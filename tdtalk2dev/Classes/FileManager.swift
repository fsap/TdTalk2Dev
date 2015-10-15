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
    
    private var keepLoading: Bool

    class var sharedInstance : FileManager {
        struct Static {
            static let instance : FileManager = FileManager()
        }
        return Static.instance
    }

    override init() {
        self.keepLoading = true
    }
    
    static func getHomeURL()->NSURL {
        return NSURL(fileURLWithPath: NSHomeDirectory())
    }
    
    ///
    /// 他アプリからエクスポートされたファイルの格納場所を取得
    ///
    static func getInboxDirString()-> String {
        return getHomeURL().URLByAppendingPathComponent(Constants.kInboxDocumentPath).absoluteString
    }
    
    static func getInboxDir()->NSURL {
        return getHomeURL().URLByAppendingPathComponent(Constants.kInboxDocumentPath)
    }
    
    ///
    /// 本棚のパスを取得
    ///
    static func getImportDirString()->String {
        return getHomeURL().URLByAppendingPathComponent(Constants.kSaveDocumentPath).absoluteString
    }

    static func getImportDir()->NSURL {
        return getHomeURL().URLByAppendingPathComponent(Constants.kSaveDocumentPath)
    }

    ///
    /// 作業用のパスを取得
    ///
    static func getTmpDirString()->String {
        return getHomeURL().URLByAppendingPathComponent(Constants.kTmpDocumentPath).absoluteString
    }
    
    static func getTmpDir()->NSURL {
        return getHomeURL().URLByAppendingPathComponent(Constants.kTmpDocumentPath)
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
        return Constants.kImportableExtensions.contains(NSString(format: "%@", NSURL(fileURLWithPath:filename).pathExtension!) as String)
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
            // ToDo: 例外処理
            try! self.fileManager.removeItemAtPath(expandDir)
        }
        return SSZipArchive.unzipFileAtPath(importFilePath, toDestination: expandDir)
    }
    
    ///
    /// ファイルを検索
    /// :param: ファイル名(ディレクトリも可)
    /// :param: 対象ディレクトリ
    /// :param: 再帰的に検索を行うかどうか
    func searchFile(filename: String, targetDir: String, recursive: Bool, inout result: String?)->Bool {
        
        let target: String = targetDir.stringByRemovingPercentEncoding!

        // 対象ディレクトリが存在しない
        if !exists(target) {
            LogE(NSString(format: "Search target directory not found. dir:%@", target))
            return false
        }
        
        // 配下のファイルを取得
        var contents: [String] = []
        do {
            contents = try self.fileManager.contentsOfDirectoryAtPath(target)
        } catch let error as NSError {
            LogE(NSString(format: "Search target directory has no contents. dir:%@ [%d][msg]", target, error.code, error.description))
            return false
        }
        for c in contents {
//            let c: String  = c as! String
            let content: String = c.stringByRemovingPercentEncoding!
            Log(NSString(format: "content:%@", content))
            // 中身のファイルチェック
            var isDir = ObjCBool(false)
            if (!self.fileManager.fileExistsAtPath(NSURL(fileURLWithPath: target).URLByAppendingPathComponent(content).absoluteString, isDirectory: &isDir)) {
                continue
            }
            
            // システムファイルはスキップ
            if isSystemFile(content) {
                continue
            }
            
            // ディレクトリの場合で再帰的に検索する場合はサブディレクトリ検索
            if (isDir && recursive) {
                if searchFile(filename, targetDir: NSURL(fileURLWithPath: target).URLByAppendingPathComponent(content).absoluteString, recursive: recursive, result: &result) {
                    return true
                }
                continue
            }
            
            // ファイル名をチェック
            if content == filename {
                result = NSURL(fileURLWithPath: target).URLByAppendingPathComponent(content).absoluteString
                return true
            }
        }
        
        return false
    }

    ///
    /// 拡張子を指定してファイルを検索
    /// :param: 拡張子
    /// :param: 対象ディレクトリ
    /// :param: 再帰的に検索を行うかどうか
    func searchExtension(ext: String, targetDir: String, recursive: Bool, inout result: String?)->Bool {
        
        let target: String = targetDir.stringByRemovingPercentEncoding!
        
        // 対象ディレクトリが存在しない
        if !exists(target) {
            LogE(NSString(format: "Search target directory not found. dir:%@", target))
            return false
        }
        
        // 配下のファイルを取得
        var contents: [String] = []
        do {
            contents = try self.fileManager.contentsOfDirectoryAtPath(target)
        } catch let error as NSError {
            LogE(NSString(format: "Search target directory has no contents. dir:%@ [%d][msg]", target, error.code, error.description))
            return false
        }

        for c in contents {
//            let c: String  = c as! String
            let content: String = c.stringByRemovingPercentEncoding!
            Log(NSString(format: "content:%@", content))
            // 中身のファイルチェック
            var isDir = ObjCBool(false)
            if (!self.fileManager.fileExistsAtPath(NSURL(fileURLWithPath: target).URLByAppendingPathComponent(content).absoluteString, isDirectory: &isDir)) {
                continue
            }
            
            // システムファイルはスキップ
            if isSystemFile(content) {
                continue
            }
            
            // ディレクトリの場合で再帰的に検索する場合はサブディレクトリ検索
            if (isDir && recursive) {
                if searchExtension(ext, targetDir: NSURL(fileURLWithPath: target).URLByAppendingPathComponent(content).absoluteString, recursive: recursive, result: &result) {
                    return true
                }
                continue
            }
            
            // 拡張子をチェック
            if NSURL(fileURLWithPath: content).pathExtension == ext {
                result = NSURL(fileURLWithPath: target).URLByAppendingPathComponent(content).absoluteString
                return true
            }
        }
        
        return false
    }
    
    //
    // インポートを開始するにあたっての初期処理
    //
    func initImport()->Void {
        if !(exists(FileManager.getImportDirString())) {
            do {
                try self.fileManager.createDirectoryAtPath(FileManager.getImportDirString(), withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                LogE(NSString(format: "Failed to create dir. dir:[%@] [%d][%@]", FileManager.getImportDirString(), error.code, error.description))
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
    func loadXmlFiles(xmlFilePaths:[String], saveDir: String, metadata: Metadata)->String {
        Log(NSString(format: "xml_file_path:%@", xmlFilePaths))
        if xmlFilePaths.count == 0 {
            LogE(NSString(format: "No xml files. [%@]", xmlFilePaths))
            return ""
        }
        
        // コンテンツ読み出し
        let brllist:BrlBuffer = BrlBuffer()
        brllist.Setinit()
        let file = File()
        file.DataSet(brllist)
        var headInfo: TDV_HEAD = TDV_HEAD()
        memset(&headInfo, 0x00, sizeof(TDV_HEAD))
        // メタ情報の設定
        switch metadata.language.lowercaseString {
        case Languages.ja.langString():
            headInfo.VoiceGengo = Languages.ja.rawValue
            break
        case Languages.en_us.langString():
            headInfo.VoiceGengo = Languages.en_us.rawValue
            break
        default:
            break
        }
        
        for (index,xml) in xmlFilePaths.enumerate() {
            if !keepLoading {
                keepLoading = true
                return ""
            }
            
            let xmlFile:String = xml
            Log(NSString(format: "xml:%@", xmlFile))
            
            let tagetFile:[CChar] = xml.cStringUsingEncoding(NSUTF8StringEncoding)!
            let mode:Int32 = index == 0 ? 0 : 1
            file.LoadXmlFile(tagetFile, readMode: mode)
        }
        // 一時保存
        let saveUrl: NSURL = NSURL(fileURLWithPath: saveDir)
        let titleBaseName = NSURL(fileURLWithPath: saveUrl.lastPathComponent!).URLByDeletingPathExtension?.absoluteString
        let saveFileName:String = NSURL(fileURLWithPath: saveDir).URLByAppendingPathComponent(titleBaseName! + ".tdv").absoluteString
        Log(NSString(format: "save_to:%@", saveFileName))
        if !(file.SaveTdvFile(saveFileName.cStringUsingEncoding(NSUTF8StringEncoding)!, head:&headInfo)) {
            LogE(NSString(format: "Failed to save tdv file. save_file[%@]", saveFileName))
            keepLoading = true
            return ""
        }
        keepLoading = true

        return saveFileName
    }
    
    func cancelLoad() {
        keepLoading = false
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
        let saveFileName = NSURL(fileURLWithPath: importFilePath).lastPathComponent
        // タイトル名
        let titleBaseName = NSURL(fileURLWithPath: saveFileName!).URLByDeletingPathExtension!.absoluteString
        // 保存先ディレクトリ
        let saveDir: NSURL = FileManager.getImportDir().URLByAppendingPathComponent(titleBaseName)
        // 保存先フルパス
        let saveFilePath = saveDir.URLByAppendingPathComponent(saveFileName!).absoluteString
        Log(NSString(format: "save_to:%@", saveFilePath))
        
        // すでに取り込み済み
        if exists(saveFilePath) {
            return TTErrorCode.FileAlreadyExists
        }
        
        // 保存用ディレクトリの作成
        do {
            try self.fileManager.createDirectoryAtPath(saveDir.absoluteString, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            Log(NSString(format: "Failed to create dir for save. dir:[%@] [%d][%@]", saveDir, error.code, error.description))
            return TTErrorCode.FailedToSaveFile
        }
        
        // 保存
        do {
            try self.fileManager.copyItemAtPath(importFilePath, toPath: saveFilePath)
        } catch let error as NSError {
            Log(NSString(format: "Failed to save file. save_path:[%@] [%d][%@]", saveFilePath, error.code, error.description))
            return TTErrorCode.FailedToSaveFile
        }
        // パーミッションを変える
        let attr: Dictionary<String, Int> = [NSFilePosixPermissions: 777]
        do {
            try self.fileManager.setAttributes(attr, ofItemAtPath: saveFilePath)
        } catch let error as NSError {
            Log(NSString(format: "Failed to change file. attr:[%@] [%d][%@]", attr, error.code, error.description))
            return TTErrorCode.FailedToSaveFile
        }
        
        return TTErrorCode.Normal
    }
    

    // 指定ファイルを削除
    func removeFile(path:String)->TTErrorCode {
        do {
            try self.fileManager.removeItemAtPath(path)
        } catch let error as NSError {
            Log(NSString(format: "Failed to delete file. path:[%@] [%d][%@]", path, error.code, error.description))
            return TTErrorCode.FailedToDeleteFile
        }
        
        return TTErrorCode.Normal
    }

}