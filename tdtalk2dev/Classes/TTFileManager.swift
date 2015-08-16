//
//  TTFileManager.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/12.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation

enum ImportableExtension: String {
    case EXE = "exe"
    case ZIP = "zip"
}

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
//        return contains(Const.kAllowedExtensions, filename.pathExtension)
        switch filename.pathExtension {
        case ImportableExtension.EXE.rawValue:
            return true
        case ImportableExtension.ZIP.rawValue:
            return true
        default:
            break
        }
        return false
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
    
    func removeFile(path:String)->TTErrorCode {
        var err:NSError? = nil
        self.fileManager.removeItemAtPath(path, error: &err)
        if err != nil {
            Log(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
            return TTErrorCode.FailedToDeleteFile
        }
        return TTErrorCode.Normal
    }
    
    //
    // インポートを開始するにあたっての初期処理
    //
    func initImport()->Void {
        if !(exists(TTFileManager.getImportDir())) {
            var err:NSError? = nil
            self.fileManager.createDirectoryAtPath(TTFileManager.getImportDir(), withIntermediateDirectories: false, attributes: nil, error: &err)
            if err != nil {
                LogE(NSString(format: "code:[%d] msg:[%@]", err!.code, err!.description))
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
    // 内部ディレクトリを探索して指定ファイルのリストを返却
    //
    func searchXmlFiles(rootDir: String, ext: String)->[String]? {
        Log(NSString(format: "root_dir:%@", rootDir))
        
        if !(exists(rootDir)) {
            LogE(NSString(format: "Specified dircectory not found. [%@]", rootDir))
            return nil
        }
        
        var filePaths: [String] = []
        let contents = self.fileManager.contentsOfDirectoryAtPath(rootDir, error: nil)!
        for content in contents {
            var content: String = content as! String
            Log(NSString(format: "content:%@", content))
            // 中身のファイルチェック
            var isDir = ObjCBool(false)
            if (!self.fileManager.fileExistsAtPath(rootDir.stringByAppendingPathComponent(content), isDirectory: &isDir)) {
                continue
            }
            
            // システムファイルはスキップ
            if content[content.startIndex] == "_" || content[content.startIndex] == "." {
                continue
            }
            
            // ディレクトリの場合はサブディレクトリ検索
            if (isDir) {
                var paths: [String] = searchXmlFiles(rootDir.stringByAppendingPathComponent(content), ext:ext)!
                filePaths += paths
                continue
            }
            
            // 拡張子をチェック
            if content.pathExtension.lowercaseString == ext {
                filePaths.append(rootDir.stringByAppendingPathComponent(content))
            }
        }
        
        return filePaths
    }
    
    //
    // XMLファイルの読み込み
    //
    func loadXmlFiles(xmlFilePaths:[String], saveDir: String)->String {
        Log(NSString(format: "xml_file_path:%@", xmlFilePaths))
        if xmlFilePaths.count == 0 {
            LogE(NSString(format: "No xml files. [%@]", xmlFilePaths))
            return ""
        }
        
        // コンテンツ読み出し
        var brllist:BrlBuffer = BrlBuffer()
        brllist.Setinit()
        var file = File()
        file.DataSet(brllist)
        var headInfo: TDV_HEAD = TDV_HEAD()
        memset(&headInfo, 0x00, sizeof(TDV_HEAD))
        for (index,xml) in enumerate(xmlFilePaths) {
            var xmlFile:String = xml
            Log(NSString(format: "xml:%@", xmlFile))
            
            let tagetFile:[CChar] = xml.cStringUsingEncoding(NSUTF8StringEncoding)!
//            var loadFile:UnsafePointer<Int8> = NSString(string: contentsDir.stringByAppendingPathComponent(xmlFile)).UTF8String
            let mode:Int32 = index == 0 ? 0 : 1
            file.LoadXmlFile(tagetFile, readMode: mode)
        }
        // 一時保存
        let titleBaseName = saveDir.lastPathComponent.stringByDeletingPathExtension
        let saveFileName:String = saveDir.stringByAppendingPathComponent(titleBaseName + ".tdv")
        Log(NSString(format: "save_to:%@", saveFileName))
        if !(file.SaveTdvFile(saveFileName.cStringUsingEncoding(NSUTF8StringEncoding)!, head:&headInfo)) {
            LogE(NSString(format: "Failed to save tdv file. save_file[%@]", saveFileName))
            return ""
        }
        
        return saveFileName
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