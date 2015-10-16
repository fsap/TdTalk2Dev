//
//  TTBookService.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/13.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation

protocol BookServiceDelegate {
    func importStarted()
    func importCompleted()
    func importFailed()
}


//
// ブックファイル管理クラス
//
class TTBookService {
    
    var fileManager: FileManager = FileManager.sharedInstance
    var dataManager: DataManager = DataManager.sharedInstance
    
    var delegate: BookServiceDelegate?
    
    private var keepLoading: Bool
    
    class var sharedInstance : TTBookService {
        struct Static {
            static let instance : TTBookService = TTBookService()
        }
        return Static.instance
    }
    
    init () {
        self.keepLoading = true
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
        let filename: String = target.stringByRemovingPercentEncoding!

        let filepath = FileManager.getInboxDir().URLByAppendingPathComponent(filename)
        Log(NSString(format: "--- paht:%@", filepath))
        
        // ファイルの存在チェック
        if !(self.fileManager.exists(filepath.absoluteString)) {
            Log(NSString(format: "%@ not found.", filepath.absoluteString))
            return TTErrorCode.FileNotExists
        }
        
        // ファイル形式のチェック
        if !(FileManager.isValiedExtension(filename)) {
            Log(NSString(format: "Unsupported type:%@", filename))
            self.fileManager.removeFile(filepath.absoluteString)
            return TTErrorCode.UnsupportedFileType
        }
        
        return TTErrorCode.Normal;
    }
    
    //
    // ファイルの取り込み
    //
    func importDaisy(target :String, didSuccess:(()->Void), didFailure:((errorCode: TTErrorCode)->Void))->Void {
        
//        self.delegate?.importStarted()
        self.keepLoading = true
        
        let filename: String = target.stringByRemovingPercentEncoding!
        let fileUrl: NSURL = NSURL(fileURLWithPath: filename)
        // 外部から渡ってきたファイルのパス ex) sadbox/Documents/Inbox/What_Is_HTML5_.zip
        let importFilePath: String = FileManager.getInboxDir().URLByAppendingPathComponent(filename).absoluteString
        // 作業用ディレクトリ ex) sadbox/tmp/
        let tmpDir: NSURL = FileManager.getTmpDir()
        // 作業ファイル展開用ディレクトリ ex) sadbox/tmp/What_Is_HTML5_
        let expandDir: String = tmpDir.URLByAppendingPathComponent((fileUrl.URLByDeletingPathExtension?.absoluteString)!).absoluteString
        // 取り込み先ディレクトリ ex) sandbox/Library/Books/
        _ = FileManager.getImportDir()
        
        if (fileUrl.pathExtension == Constants.kImportableExtensions[0]) {
            // exe展開
            if !(self.fileManager.unzip(importFilePath, expandDir: expandDir)) {
                LogE(NSString(format: "Unable to expand:%@", filename))
                deInitImport([importFilePath], errorCode: TTErrorCode.UnsupportedFileType, didSuccess: didSuccess, didFailure: didFailure)
                return
            }
            
        } else if (fileUrl.pathExtension == Constants.kImportableExtensions[1]) {
            // zip解凍
            if !(self.fileManager.unzip(importFilePath, expandDir: expandDir)) {
                deInitImport([importFilePath], errorCode: TTErrorCode.UnsupportedFileType, didSuccess: didSuccess, didFailure: didFailure)
                return
            }
        }
        Log(NSString(format: "tmp_dir:%@", try! self.fileManager.fileManager.contentsOfDirectoryAtPath(tmpDir.absoluteString)))
        
        if !keepLoading {
            deInitImport([importFilePath], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
            return
        }
        
        // 初期化
        self.fileManager.initImport()

        let daisyManager: DaisyManager = DaisyManager.sharedInstance
        daisyManager.detectDaisyStandard(expandDir, didSuccess: { (version) -> Void in
            Log(NSString(format: "success. ver:%f", version))
            
            if !self.keepLoading {
                self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                return
            }

            let queue: dispatch_queue_t = dispatch_queue_create("loadMetaData", nil)
            dispatch_async(queue, { () -> Void in

                daisyManager.loadMetadata(expandDir, version: version, didSuccess: { (daisy) -> Void in
                    // メタ情報の読み込みに成功
                    Log(NSString(format: "success to get metadata. paths:%@", daisy.navigation.contentsPaths))
                    Log(NSString(format: "daisy: title:%@ language:%@", daisy.metadata.title, daisy.metadata.language))
                    
                    if !self.keepLoading {
                        self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }

                    let saveFilePath = self.fileManager.loadXmlFiles(daisy.navigation.contentsPaths, saveDir:expandDir, metadata: daisy.metadata)
                    if !self.keepLoading {
                        self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    if saveFilePath == "" {
                        self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.FailedToLoadFile, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    // 本棚へ登録
                    let result = self.fileManager.saveToBook(saveFilePath)
                    if result != TTErrorCode.Normal {
                        self.deInitImport([importFilePath, expandDir], errorCode: result, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    // 図書情報をDBに保存
                    let book: BookEntity = self.dataManager.getEntity(DataManager.Const.kBookEntityName) as! BookEntity
                    book.title = daisy.metadata.title
                    book.language = daisy.metadata.language
//                    book.filename = FileManager.getImportDir().stringByAppendingPathComponent(saveFilePath.lastPathComponent.stringByDeletingPathExtension)
                    let saveFileUrl: NSURL = NSURL(fileURLWithPath: saveFilePath)
                    book.filename = (NSURL(fileURLWithPath: saveFileUrl.lastPathComponent!).URLByDeletingPathExtension?.absoluteString)!
                    book.sort_num = self.getBookList().count
                    let ret = self.dataManager.save()
                    if ret != TTErrorCode.Normal {
                        self.deInitImport([importFilePath, expandDir], errorCode: ret, didSuccess: didSuccess, didFailure: didFailure)
                        return
                    }
                    
                    // 終了処理
                    self.deInitImport([importFilePath, expandDir], errorCode: TTErrorCode.Normal, didSuccess: didSuccess, didFailure: didFailure)
                    
                }, didFailure: { (errorCode) -> Void in
                    LogE(NSString(format: "[%d]Failed to load metadata. dir:%@", errorCode.rawValue, expandDir))
                    self.deInitImport([importFilePath, expandDir], errorCode: errorCode, didSuccess: didSuccess, didFailure: didFailure)
                })

            })
            
        }) { (errorCode) -> Void in
            LogE(NSString(format: "[%d]Invalid directory format. dir:%@", errorCode.rawValue, expandDir))
            self.deInitImport([importFilePath, expandDir], errorCode: errorCode, didSuccess: didSuccess, didFailure: didFailure)
        }
        
    }
    
    //
    // 読み込みキャンセル
    //
    func cancelImport() {
        self.fileManager.cancelLoad()
        keepLoading = false
    }
    
    func getImportedFiles()->[String] {

        // 取り込み先ディレクトリ
        let bookDir = FileManager.getImportDirString()
        if !(fileManager.exists(bookDir)) {
            return []
        }

        var result:[String] = []
        var files: [String] = []
        do {
            files = try self.fileManager.fileManager.contentsOfDirectoryAtPath(bookDir)
        } catch let error as NSError {
            LogE(NSString(format: "An error occurred. [%d][%@]", error.code, error.description))
        }
        for file in files {
            let file:String = file
            result.append(file)
        }
        return result
    }
    
    //
    // 保存済み図書リストを取得
    //
    func getBookList()->[BookEntity] {
        let sortDescriptor = NSSortDescriptor(key: "sort_num", ascending: false)
        let results: [BookEntity] = self.dataManager.find(DataManager.Const.kBookEntityName, condition: nil, sort: [sortDescriptor]) as! [BookEntity]

        return results
    }
    
    // 図書ファイルを削除
    func deleteBook(book: BookEntity)->TTErrorCode {
        // ファイル削除
        let filepath: NSURL = FileManager.getImportDir().URLByAppendingPathComponent(book.filename)
        let fileResult: TTErrorCode = self.fileManager.removeFile(filepath.absoluteString)
        Log(NSString(format: "remove file:%@", filepath))
        if fileResult != TTErrorCode.Normal {
            return fileResult
        }
        
        // 完了したらDBからも削除
        let dbResult: TTErrorCode = self.dataManager.remove(book)
        
        return dbResult
    }
    
    //
    // MARK: Private
    //
    
    //
    // 終了時の共通処理
    //
    func deInitImport(deleteFilePaths: [String], errorCode: TTErrorCode, didSuccess:(()->Void), didFailure:((errorCode: TTErrorCode)->Void)) {
        self.keepLoading = true
        self.fileManager.deInitImport(deleteFilePaths)
        if errorCode == TTErrorCode.Normal {
            self.delegate?.importCompleted()
            didSuccess()
        } else {
            self.delegate?.importFailed()
            didFailure(errorCode: errorCode)
        }
    }
}