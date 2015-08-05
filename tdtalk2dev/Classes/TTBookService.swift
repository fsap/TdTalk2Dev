//
//  TTBookService.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/13.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation

protocol BookServiceDelegate {
    func importCompleted()
}


//
// ブックファイル管理クラス
//
class TTBookService {
    

    var delegate: BookServiceDelegate?
    
    class var sharedInstance : TTBookService {
        struct Static {
            static let instance : TTBookService = TTBookService()
        }
        return Static.instance
    }
    
    init () {
    }
    
    deinit {
        
    }
    
    //
    // ファイル形式の検証
    //
    func validate(filename :String)->TTErrorCode {
        
        if filename == "" {
            return TTErrorCode.FailedToGetFile
        }

        var fileManager = TTFileManager.sharedInstance
        let filepath = TTFileManager.getInboxDir().stringByAppendingPathComponent(filename)
        Log(NSString(format: "--- paht:%@", filepath))
        
        // ファイルの存在チェック
        if !(fileManager.exists(filepath)) {
            Log(NSString(format: "%@ not found.", filepath))
            return TTErrorCode.FileNotExists
        }
        
        // ファイル形式のチェック
        if !(TTFileManager.isValiedExtension(filename)) {
            Log(NSString(format: "Unsupported type:%@", filename))
            fileManager.removeFile(filepath)
            return TTErrorCode.UnsupportedFileType
        }
        
        return TTErrorCode.Normal;
    }
    
    //
    // ファイルの取り込み
    //
    func importDaisy(filename :String)->TTErrorCode {
        var fileManager = TTFileManager.sharedInstance
        
        // 外部から渡ってきたファイルのパス
        let importFilePath = TTFileManager.getInboxDir().stringByAppendingPathComponent(filename)
        // 作業用ディレクトリ
        let tmpDir = TTFileManager.getTmpDir()
        // 作業ファイル展開用ディレクトリ
        let expandDir = tmpDir.stringByAppendingPathComponent(filename.stringByDeletingPathExtension)
        // 取り込み先ディレクトリ
        let bookDir = TTFileManager.getImportDir()
        
        if (filename.pathExtension == "exe") {
            // exe展開
            
        } else if (filename.pathExtension == "zip") {
            // zip解凍
            if !(fileManager.unzip(importFilePath, expandPath: expandDir)) {
                fileManager.deInitImport([importFilePath])
                return TTErrorCode.UnsupportedFileType
            }
        }
        Log(NSString(format: "unzip file:%@", fileManager.fileManager.contentsOfDirectoryAtPath(tmpDir, error: nil)!))
        
        // 初期化
        fileManager.initImport()
        
        // 展開
        let saveFilePath = fileManager.loadXmlFiles(expandDir)
        if saveFilePath == "" {
            fileManager.deInitImport([importFilePath, expandDir])
            return TTErrorCode.FailedToLoadFile
        }
        
        // 本棚へ登録
        var result = fileManager.saveToBook(saveFilePath)
        if result != TTErrorCode.Normal {
            return result
        }
        
        // ToDo:作品メタ情報とファイル情報をCoreData等で永続化する
        
        
        // 終了処理
        fileManager.deInitImport([importFilePath, expandDir])
        
        self.delegate?.importCompleted()
        
        return TTErrorCode.Normal
    }
    
    func getImportedFiles()->[String] {
        var fileManager = TTFileManager.sharedInstance

        // 取り込み先ディレクトリ
        let bookDir = TTFileManager.getImportDir()
        if !(fileManager.exists(bookDir)) {
            return []
        }

        var result:[String] = []
        let files = fileManager.fileManager.contentsOfDirectoryAtPath(bookDir, error: nil)!
        for file in files {
            var file:String = file as! String
            result.append(file)
        }
        return result
    }
    
}