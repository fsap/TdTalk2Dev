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
    func importDaisy(target :String, didSuccess:(()->Void), didFailure:((errorCode: TTErrorCode)->Void))->Void {
        
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
            if !(self.fileManager.unzip(importFilePath, expandPath: expandDir)) {
                self.fileManager.deInitImport([importFilePath])
                LogE(NSString(format: "Unable to expand:%@", filename))
                didFailure(errorCode:TTErrorCode.UnsupportedFileType)
                return
            }
            
        } else if (filename.pathExtension == ImportableExtension.ZIP.rawValue) {
            // zip解凍
            if !(self.fileManager.unzip(importFilePath, expandPath: expandDir)) {
                self.fileManager.deInitImport([importFilePath])
                LogE(NSString(format: "Unable to expand:%@", filename))
                didFailure(errorCode:TTErrorCode.UnsupportedFileType)
                return
            }
        }
        Log(NSString(format: "tmp_dir:%@", self.fileManager.fileManager.contentsOfDirectoryAtPath(tmpDir, error: nil)!))
        
        // 初期化
        self.fileManager.initImport()
        
        // メタ情報が記載されているopfファイルをサーチ
        self.fileManager.detectOpfPath(expandDir, didSuccess: { (opfPath) -> Void in
            let queue: dispatch_queue_t = dispatch_queue_create("opfMetaData", nil)
            dispatch_async(queue, { () -> Void in
                
                // メタ情報を取得
                var opfManager: OpfManager = OpfManager.sharedInstance
                opfManager.startParseOpfFile(opfPath, didParseSuccess: { (opf) -> Void in
                    // 取得成功
                    Log(NSString(format: "parse success meta:%@ xml:%@", opf.dcMetadata, opf.manifestItem))
                    
                    // 展開
                    let xmlFilePath: String = expandDir.stringByAppendingPathComponent(opf.manifestItem.href)
                    let saveFilePath = self.fileManager.loadXmlFiles([xmlFilePath], saveDir:expandDir)
                    if saveFilePath == "" {
                        self.fileManager.deInitImport([importFilePath, expandDir])
                        didFailure(errorCode:TTErrorCode.FailedToLoadFile)
                        return
                    }
                    
                    // 本棚へ登録
                    var result = self.fileManager.saveToBook(saveFilePath)
                    if result != TTErrorCode.Normal {
                        self.fileManager.deInitImport([importFilePath, expandDir])
                        didFailure(errorCode:result)
                        return
                    }
                    
                    // 図書情報をDBに保存
                    var book: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
                    book.title = opf.dcMetadata.title
                    book.filename = TTFileManager.getImportDir().stringByAppendingPathComponent(saveFilePath.lastPathComponent.stringByDeletingPathExtension)
                    book.sort_num = self.getBookList().count
                    var ret = self.dataManager.save()
                    if ret != TTErrorCode.Normal {
                        self.fileManager.deInitImport([importFilePath, expandDir])
                        didFailure(errorCode:ret)
                        return
                    }
                    
                    // 終了処理
                    self.fileManager.deInitImport([importFilePath, expandDir])
                    
                    self.delegate?.importCompleted()
                    
                    didSuccess()
                    
                    
                }) { (errorCode) -> Void in
                    // 取得失敗
                    LogE("Failed to parse opf file.")
                    didFailure(errorCode: errorCode)
                }
            })
            
            
        }) { (errorCode) -> Void in
            LogE(NSString(format: "OPF file not found. [%d] root:%@", errorCode.rawValue, expandDir))
            self.fileManager.deInitImport([importFilePath, expandDir])
            didFailure(errorCode: errorCode)
        }
        
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