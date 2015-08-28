//
//  LodingView.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/22.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

class LoadingView: UIView, BookListViewDelegate {
    
    private var activityIndicator: UIActivityIndicatorView
    private var sound_source: dispatch_source_t?

    
    override init(frame: CGRect) {
        activityIndicator = UIActivityIndicatorView()
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(parentView: UIView) {
        self.init(frame: parentView.frame)
        
        createView(parentView)
    }
    
    private func createView(parentView: UIView) {
        
        //
        // ローディングViewの生成
        //
        self.frame = parentView.frame
        self.backgroundColor = UIColor.grayColor()
        self.alpha = 0.5
        
        // メッセージラベル
        var msgView: UIView = UIView(frame: CGRectMake(0, 0, 200, 200))
        var msgLabel: UILabel = UILabel(frame: CGRectMake(0, 0, 200, 20))
        msgView.center = parentView.center
        msgView.backgroundColor = UIColor.clearColor()
        msgLabel.textColor = UIColor.whiteColor()
        msgLabel.textAlignment = .Center
        msgLabel.text = NSLocalizedString("msg_loading", comment: "")
        msgLabel.sizeToFit()
        msgLabel.center = CGPoint(x: msgView.frame.size.width / 2, y: msgView.frame.size.height / 2)
        
        // インジケーター
        activityIndicator.frame = CGRectMake(0, 0, 50, 50)
        activityIndicator.center = CGPoint(x: msgView.frame.size.width / 2, y: msgLabel.frame.origin.y + msgLabel.frame.size.height + 20)
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        
        msgView.addSubview(msgLabel)
        msgView.addSubview(activityIndicator)
        self.addSubview(msgView)
        
        parentView.addSubview(self)
    }
    
    private func clearView() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
    }
    
    func start() {
        activityIndicator.startAnimating()
        
        /*
        サウンド再生
        */
        let queue = dispatch_queue_create("book_loading", nil)
        sound_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        // キャンセルハンドラ
        dispatch_source_set_cancel_handler(sound_source!, { () -> Void in
            if self.sound_source != nil {
                self.sound_source = nil;
            }
        })
        
        // タイマー
        dispatch_source_set_timer(
            sound_source!,
            dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)),
            2 * NSEC_PER_SEC,
            0)
        
        dispatch_source_set_event_handler(sound_source!, { () -> Void in
            // システムサウンドを鳴らす
            LogM("sound...")
            AudioServicesPlaySystemSound(1104)
        })
        
        dispatch_resume(sound_source!);
        
    }
    
    func stop() {
        activityIndicator.stopAnimating()
        
        if sound_source != nil {
            dispatch_source_cancel(sound_source!)
        }
        self.removeFromSuperview()
    }
    
    //
    // MARK: BookListViewDelegate
    //
    func needRedraw(view: UIView) {
        Log(NSString(format: "view x:%f y:%f", view.frame.size.width, view.frame.size.height))
        // ローディング中の画面回転対応
        if activityIndicator.isAnimating() {
            self.clearView()
            createView(view)
        }
    }
}