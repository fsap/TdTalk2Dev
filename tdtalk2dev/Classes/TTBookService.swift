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
    
    var fileManager: TTFileManager = TTFileManager.sharedInstance
    var dataManager: DataManager = DataManager.sharedInstance
    
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
    func validate(target :String)->TTErrorCode {
        
        if target == "" {
            return TTErrorCode.FailedToGetFile
        }
        var filename: String = target.stringByRemovingPercentEncoding!

        let filepath = TTFileManager.getInboxDir().stringByAppendingPathComponent(filename)
        Log(NSString(format: "--- paht:%@", filepath))
        
        // ファイルの存在チェック
        if !(self.fileManager.exists(filepath)) {
            Log(NSString(format: "%@ not found.", filepath))
            return TTErrorCode.FileNotExists
        }
        
        // ファイル形式のチェック
        if !(TTFileManager.isValiedExtension(filename)) {
            Log(NSString(format: "Unsupported type:%@", filename))
            self.fileManager.removeFile(filepath)
            return TTErrorCode.UnsupportedFileType
        }
        
        return TTErrorCode.Normal;
    }
    
    //
    // ファイルの取り込み
    //
    func importDaisy(target :String)->TTErrorCode {
        
        var filename: String = target.stringByRemovingPercentEncoding!
        // 外部から渡ってきたファイルのパス ex) sadbox/Documents/Inbox/What_Is_HTML5_.zip
        let importFilePath = TTFileManager.getInboxDir().stringByAppendingPathComponent(filename)
        // 作業用ディレクトリ ex) sadbox/tmp/
        let tmpDir = TTFileManager.getTmpDir()
        // 作業ファイル展開用ディレクトリ ex) sadbox/tmp/What_Is_HTML5_
        let expandDir = tmpDir.stringByAppendingPathComponent(filename.stringByDeletingPathExtension)
        // 取り込み先ディレクトリ ex) sandbox/Library/Books/
        let bookDir = TTFileManager.getImportDir()
        
        if (filename.pathExtension == ImportableExtension.EXE.rawValue) {
            // exe展開
            
        } else if (filename.pathExtension == ImportableExtension.ZIP.rawValue) {
            // zip解凍
            if !(self.fileManager.unzip(importFilePath, expandPath: expandDir)) {
                self.fileManager.deInitImport([importFilePath])
                Log(NSString(format: "Unable to expand:%@", filename))
                return TTErrorCode.UnsupportedFileType
            }
        }
        Log(NSString(format: "tmp_dir:%@", self.fileManager.fileManager.contentsOfDirectoryAtPath(tmpDir, error: nil)!))
        
        // 初期化
        self.fileManager.initImport()
        
        // メタ情報が記載されているopfファイルをサーチ
        let opfPath: String? = self.fileManager.detectOpfPath(expandDir)
        if opfPath == nil {
            LogE(NSString(format: "OPF file not found. root:%@", expandDir))
            self.fileManager.deInitImport([importFilePath, expandDir])
            return TTErrorCode.OpfFileNotFound
        }
        
        // メタ情報を取得
        self.fileManager.startParseXmlFormatFile(opfPath!, didParseSuccess: { (metaData, xmlItem) -> Void in
            Log(NSString(format: "parse success meta:%@ xml:%@", metaData, xmlItem))
            self.fileManager.deInitImport([importFilePath, expandDir])
            
        }) { (errorCode) -> Void in
            LogE(NSString(format: "OPF file not found. root:%@", expandDir))
            self.fileManager.deInitImport([importFilePath, expandDir])

        }
        return TTErrorCode.Normal
        
/* ToDo:見直し
        // 展開
        let xmlFiles: [String] = fileManager.searchXmlFiles(expandDir, ext: "xml")!
        let saveFilePath = fileManager.loadXmlFiles(xmlFiles, saveDir:expandDir)
        if saveFilePath == "" {
            fileManager.deInitImport([importFilePath, expandDir])
            return TTErrorCode.FailedToLoadFile
        }
        
        // 本棚へ登録
        var result = fileManager.saveToBook(saveFilePath)
        if result != TTErrorCode.Normal {
            return result
        }
        
        // 図書情報をDBに保存
        var book: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
        book.title = saveFilePath.lastPathComponent.stringByDeletingPathExtension
        book.filename = TTFileManager.getImportDir().stringByAppendingPathComponent(saveFilePath.lastPathComponent.stringByDeletingPathExtension)
        book.sort_num = self.getBookList().count
        var ret = self.dataManager.save()
        if ret != TTErrorCode.Normal {
            self.fileManager.deInitImport([importFilePath, expandDir])
            return ret
        }
        
        // 終了処理
        self.fileManager.deInitImport([importFilePath, expandDir])
        
        self.delegate?.importCompleted()
        
        return TTErrorCode.Normal
*/
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
    
    func getBookList()->[BookEntity] {
        let sortDescriptor = NSSortDescriptor(key: "sort_num", ascending: true)
        let results: [BookEntity] = self.dataManager.find(DataManager.Const.kBookEntityName, condition: nil, sort: [sortDescriptor]) as! [BookEntity]

        return results
    }
    
    // 図書ファイルを削除
    func deleteBook(book: BookEntity)->TTErrorCode {
        // ファイル削除
        let filepath: String = book.filename//.stringByRemovingPercentEncoding!
        let fileResult: TTErrorCode = self.fileManager.removeFile(filepath)
        if fileResult != TTErrorCode.Normal {
            return fileResult
        }
        
        // 完了したらDBからも削除
        var dbResult: TTErrorCode = self.dataManager.remove(book)
        
        return dbResult
    }
}