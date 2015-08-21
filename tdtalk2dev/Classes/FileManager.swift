//
//  FileManager.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

class FileManager: NSObject {
    
    let fileManager : NSFileManager = NSFileManager.defaultManager()
    
    class var sharedInstance : FileManager {
        struct Static {
            static let instance : FileManager = FileManager()
        }
        return Static.instance
    }

    override init() {
        
    }
    
    ///
    /// 他アプリからエクスポートされたファイルの格納場所を取得
    ///
    static func getInboxDir()-> String {
        return NSHomeDirectory().stringByAppendingPathComponent(Constants.kInboxDocumentPath)
    }
    
    ///
    /// 本棚のパスを取得
    ///
    static func getImportDir()->String {
        return NSHomeDirectory().stringByAppendingPathComponent(Constants.kSaveDocumentPath)
    }
    
    ///
    /// 作業用のパスを取得
    ///
    static func getTmpDir()->String {
        return NSHomeDirectory().stringByAppendingPathComponent(Constants.kTmpDocumentPath)
    }
    
    ///
    /// 指定したファイル(ディレクトリ)が存在するか
    /// :param: String ファイルまたはディレクトリ
    func exists(path : String)->Bool {
        return self.fileManager.fileExistsAtPath(path)
    }
    
    ///
    /// 有効な拡張子か
    /// :param: String ファイル名
    static func isValiedExtension(filename : String)->Bool {
        return contains(Constants.kImportableExtensions, filename.pathExtension)
    }
    
    ///
    /// システムファイルかどうか
    ///
    func isSystemFile(filename: String)->Bool {
        if filename[filename.startIndex] == "_" || filename[filename.startIndex] == "." {
            return true
        }
        return false
    }
    
    ///
    /// zip解凍
    /// :param: String 圧縮ファイルのファイル名をフルパスで指定
    /// :param: String 展開先のディレクトリ
    func unzip(importFilePath : String, expandDir : String)->Bool {
        if (exists(expandDir)) {
            self.fileManager.removeItemAtPath(expandDir, error: nil)
        }
        return SSZipArchive.unzipFileAtPath(importFilePath, toDestination: expandDir)
    }
    
    ///
    /// ファイルを検索
    /// :param: ファイル名(ディレクトリも可)
    /// :param: 対象ディレクトリ
    /// :param: 再帰的に検索を行うかどうか
    func searchFile(filename: String, targetDir: String, recursive: Bool)->Bool {
        
        let target: String = targetDir.stringByRemovingPercentEncoding!

        // 対象ディレクトリが存在しない
        if !exists(target) {
            LogE(NSString(format: "Search target directory not found. dir:%@", target))
            return false
        }
        
        // 配下のファイルを取得
        var err: NSError? = nil
        let contents = self.fileManager.contentsOfDirectoryAtPath(target, error: &err)!
        if err != nil {
            LogE(NSString(format: "Search target directory has no contents. dif:%@ err_code:%d msg:%@", target, err!.code, err!.description))
            return false
        }
        for c in contents {
            let c: String  = c as! String
            let content: String = c.stringByRemovingPercentEncoding!
            Log(NSString(format: "content:%@", content))
            // 中身のファイルチェック
            var isDir = ObjCBool(false)
            if (!self.fileManager.fileExistsAtPath(target.stringByAppendingPathComponent(content), isDirectory: &isDir)) {
                continue
            }
            
            // システムファイルはスキップ
            if isSystemFile(content) {
                continue
            }
            
            // ディレクトリの場合で再帰的に検索する場合はサブディレクトリ検索
            if (isDir && recursive) {
                if searchFile(filename, targetDir: content, recursive: recursive) {
                    return true
                }
                continue
            }
            
            // ファイル名をチェック
            if content == filename {
                return true
            }
        }
        
        return false
    }
    
    // 指定ファイルを削除
    func removeFile(path:String)->TTErrorCode {
        var err:NSError? = nil
        self.fileManager.removeItemAtPath(path, error: &err)
        if err != nil {
            Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            return TTErrorCode.FailedToDeleteFile
        }
        return TTErrorCode.Normal
    }

}