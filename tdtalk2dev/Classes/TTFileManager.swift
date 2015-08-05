//
//  TTFileManager.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/12.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation

class TTFileManager : NSObject {
    
    // 定数
    struct Const {
        static let kInboxDocumentPath :String = "Documents/Inbox"
        static let kTmpDocumentPath :String = "tmp"
        static let kImportDocumentPath :String = "Library/Books"
        static let kAllowedExtensions : Array = ["zip", "exe"]
    }
    
    let fileManager : NSFileManager
    
    class var sharedInstance : TTFileManager {
        struct Static {
            static let instance : TTFileManager = TTFileManager()
        }
        return Static.instance
    }
    
    override init() {
        self.fileManager = NSFileManager.defaultManager()
    }
    
    static func getInboxDir()-> String {
//        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
//        return (paths[0] as! String).stringByAppendingPathComponent(Const.kInboxDocumentPath)
        return NSHomeDirectory().stringByAppendingPathComponent(Const.kInboxDocumentPath)
    }
    
    static func getImportDir()->String {
        return NSHomeDirectory().stringByAppendingPathComponent(Const.kImportDocumentPath)
    }
    
    static func getTmpDir()->String {
        return NSHomeDirectory().stringByAppendingPathComponent(Const.kTmpDocumentPath)
    }
    
    func exists(path : String)->Bool {
        return self.fileManager.fileExistsAtPath(path)
    }
    
    static func isValiedExtension(filename : String)->Bool {
        return contains(Const.kAllowedExtensions, filename.pathExtension)
    }
    
    /**
     * Inboxへのファイル複製はOSによって行われ、重複があった場合hはxxx-1.ext に自動でリネームされる
     * なので取り込み済みのチェックはファイル展開時などに行うべき
     */
    func duplicated(filename : String)->Bool {
        /*
        var error : NSError? = nil
        var filesAtPath = self.fileManager.contentsOfDirectoryAtPath(filename.stringByDeletingLastPathComponent, error: &error)!
        if error != nil {
            Log("No files. dir:" + filename.stringByDeletingLastPathComponent)
            return false
        }
        
        if let files = filesAtPath as Array {
            for file in files {
                if filename.lastPathComponent == file as! String {
                    return true
                }
            }
        }
        */
        return false
    }
    
    func unzip(importFile : String, expandPath : String)->Bool {
        if (exists(expandPath)) {
            self.fileManager.removeItemAtPath(expandPath, error: nil)
        }
        return Main.unzipFileAtPath(importFile, toDestination: expandPath)
    }
    
    func removeFile(path:String)->Void {
        var err:NSError? = nil
        self.fileManager.removeItemAtPath(path, error: &err)
        if err != nil {
            Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
        }
    }
    
    //
    // インポートを開始するにあたっての初期処理
    //
    func initImport()->Void {
        if !(exists(TTFileManager.getImportDir())) {
            var err:NSError? = nil
            self.fileManager.createDirectoryAtPath(TTFileManager.getImportDir(), withIntermediateDirectories: false, attributes: nil, error: &err)
            if err != nil {
                Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            }
        }
    }
    
    //
    // インポート終了後の共通処理
    //
    func deInitImport(paths:[String])->Void {
        var isDir = ObjCBool(true)
        for path in paths {
            if !(self.fileManager.fileExistsAtPath(path, isDirectory: &isDir)) {
                continue
            }
            removeFile(path)
        }
    }
    
    //
    // XMLファイルの読み込み
    //
    func loadXmlFiles(xmlRootDir:String)->String {
        Log(NSString(format: "xml_root_dir:%@", xmlRootDir))
        if !(exists(xmlRootDir)) {
            return ""
        }
        
        // 内部ディレクトリを探索
        let dirs = self.fileManager.contentsOfDirectoryAtPath(xmlRootDir, error: nil)!
        var contentsDir:String = xmlRootDir
        for dir in dirs {
            var dir:String = dir as! String
            Log(NSString(format: "dir:%@", dir))
            // システムファイルはスキップ
            if dir[dir.startIndex] == "_" || dir[dir.startIndex] == "." {
                continue
            }
            contentsDir = xmlRootDir.stringByAppendingPathComponent(dir)
            Log(NSString(format: "contentsDir:%@", contentsDir))
            
            var isDir = ObjCBool(true)
            if (self.fileManager.fileExistsAtPath(contentsDir, isDirectory: &isDir)) {
                break
            }
        }
        // xmlファイルの上位フォルダ名をタイトル名に使う
        let titleBaseName = contentsDir.lastPathComponent.stringByDeletingPathExtension
        
        // コンテンツ読み出し
        let contents = self.fileManager.contentsOfDirectoryAtPath(contentsDir, error: nil)!
        var brllist:BrlBuffer = BrlBuffer()
        brllist.Setinit()
        var file = File()
        file.DataSet(brllist)
        for (index,xml) in enumerate(contents) {
            var xmlFile:String = xml as! String
            Log(NSString(format: "xml:%@", xmlFile))
            
            let tagetFile:[CChar] = contentsDir.stringByAppendingPathComponent(xmlFile).cStringUsingEncoding(NSUTF8StringEncoding)!
//            var loadFile:UnsafePointer<Int8> = NSString(string: contentsDir.stringByAppendingPathComponent(xmlFile)).UTF8String
            let mode:Int32 = index == 0 ? 0 : 1
            file.LoadXmlFile(tagetFile, readMode: mode)
        }
        // 一時保存
        let saveFileName:String = contentsDir.stringByAppendingPathComponent(titleBaseName + ".tdv")
        Log(NSString(format: "save_to:%@", contentsDir.stringByAppendingPathComponent(titleBaseName + ".tdv")))
        if file.SaveTdvFile(saveFileName.cStringUsingEncoding(NSUTF8StringEncoding)!) == 0 {
            return saveFileName
        }
        
        return ""
    }
    
    //
    // 指定ファイルをブックへ登録
    //
    func saveToBook(importFilePath:String)->TTErrorCode {
        Log(NSString(format: "import_file:%@", importFilePath))
        if !(exists(importFilePath)) {
            return TTErrorCode.FailedToLoadFile
        }
        
        // 保存ファイル名
        let saveFileName = importFilePath.lastPathComponent
        // タイトル名
        let titleBaseName = saveFileName.stringByDeletingPathExtension
        // 保存先ディレクトリ
        let saveDir = TTFileManager.getImportDir().stringByAppendingPathComponent(titleBaseName)
        // 保存先フルパス
        let saveFilePath = saveDir.stringByAppendingPathComponent(saveFileName)
        Log(NSString(format: "save_to:%@", saveFilePath))
        
        // すでに取り込み済み
        if exists(saveFilePath) {
            return TTErrorCode.FileAlreadyExists
        }
        
        // 保存用ディレクトリの作成
        var err:NSError?
        self.fileManager.createDirectoryAtPath(saveDir, withIntermediateDirectories: false, attributes: nil, error: &err)
        if err != nil {
            Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            return TTErrorCode.FailedToSaveFile
        }
        
        // 保存
        self.fileManager.copyItemAtPath(importFilePath, toPath: saveFilePath, error: &err)
        if err != nil {
            Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            return TTErrorCode.FailedToSaveFile
        }

        return TTErrorCode.Normal
    }
}