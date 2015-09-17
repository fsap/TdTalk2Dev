//
//  AppDelegate.swift
//  TdTalk2Dev
//
//  Created by 藤原修市 on 2015/07/30.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var alertController: TTAlertController = TTAlertController(nibName: nil, bundle: nil)
    var loadingView: LoadingView?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        LogM("lifecycle:launch")
        // Override point for customization after application launch.
        if launchOptions != nil {
            var options = launchOptions!
            var url = options[UIApplicationLaunchOptionsURLKey] as! NSURL;
            Log(NSString(format: "url:%@", url.absoluteString!))
            
            if !self.startImportBook(url.absoluteString!) {
                return false
            }
        }
        
        return true
    }

    // バックグラウンドにいる場合はこちらがキックされる
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        Log(NSString(format: "lifecycle:handle_open_url:%@", url.lastPathComponent!))
        // Override point for customization after application launch.
        
        if !self.startImportBook(url.absoluteString!) {
            return false
        }

        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        Log("lifecycle:resign_active")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        Log("lifecycle:background")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        Log("lifecycle:foreground")
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        Log("lifecycle:become_active")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        Log("lifecycle:terminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    private func startImportBook(url: String)->Bool {
        
        startLoading()
        
        var bookService = TTBookService.sharedInstance
        var ret = bookService.validate(url.lastPathComponent)
        
        // エラーメッセージ
        switch ret {
        case TTErrorCode.Normal:
            break
        default:
            alertController.show(
                window?.rootViewController!,
                title:NSLocalizedString("dialog_title_error", comment: ""),
                message:TTError.getErrorMessage(ret), actionOk: {() -> Void in})
            stopLoading()
            return false
        }
        
        // インポート
        bookService.importDaisy(url.lastPathComponent, didSuccess: { () -> Void in
            // 完了
            LogM("Import Success.")
            self.stopLoading()
            
        }) { (errorCode) -> Void in
            // エラーダイアログ
            LogE(NSString(format: "err. code:%d", errorCode.rawValue))
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.alertController.show(
                    self.window?.rootViewController!,
                    title:NSLocalizedString("dialog_title_error", comment: ""),
                    message:TTError.getErrorMessage(errorCode),
                    actionOk: {() -> Void in
                        self.stopLoading()
                })
            })
        }
        return true
    }
    
    // ローディング中の処理
    private func startLoading()->Void {
        LogM("start loading")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingView = LoadingView(parentView: self.window!.rootViewController!.view)
//          self.loadingView?.delegate = self
//          self.delegate = self.loadingView
            self.loadingView?.hidden = false
            self.loadingView?.start()
        })
    }
    
    // ローディング中のサウンド停止
    private func stopLoading()->Void {
        LogM("stop loading")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingView?.stop()
            self.loadingView?.hidden = true
            self.loadingView = nil
        })
    }
}

