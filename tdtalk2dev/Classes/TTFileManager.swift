//
//  TTFileManager.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/12.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import Foundation
import AudioToolbox

enum ImportableExtension: String {
    case EXE = "exe"
    case ZIP = "zip"
}

class TTFileManager : NSObject, NSXMLParserDelegate {
    
    // 定数
    struct Const {
        static let kInboxDocumentPath: String = "Documents/Inbox"
        static let kTmpDocumentPath: String = "tmp"
        static let kImportDocumentPath: String = "Library/Books"
        static let kAllowedExtensions: Array = ["zip", "exe"]
    }
    
    let fileManager : NSFileManager
    
    private var sound_source: dispatch_source_t?
    
    private var didParseOpfSuccess: ((metaData: DCMetadata, xmlItem: ManifestItem)->Void)?
    private var didParseOpfFailure: ((errorCode: TTErrorCode)->Void)?
    private var metaData: DCMetadata
    private var xmlItem: ManifestItem
    private var isInDcMetadata: Bool
    private var isInManifest: Bool
    private var currentElement: String

    
    class var sharedInstance : TTFileManager {
        struct Static {
            static let instance : TTFileManager = TTFileManager()
        }
        return Static.instance
    }
    
    override init() {
        self.fileManager = NSFileManager.defaultManager()
        self.didParseOpfSuccess  = nil
        self.didParseOpfFailure = nil
        self.metaData = DCMetadata()
        self.xmlItem = ManifestItem()
        self.isInDcMetadata = false
        self.isInManifest = false
        self.currentElement = ""
    }
    
    // 他アプリからエクスポートされたファイルの格納場所を取得
    static func getInboxDir()-> String {
        return NSHomeDirectory().stringByAppendingPathComponent(Const.kInboxDocumentPath)
    }
    
    // 本棚のパスを取得
    static func getImportDir()->String {
        return NSHomeDirectory().stringByAppendingPathComponent(Const.kImportDocumentPath)
    }
    
    // 作業用のパスを取得
    static func getTmpDir()->String {
        return NSHomeDirectory().stringByAppendingPathComponent(Const.kTmpDocumentPath)
    }
    
    // 指定したファイル(ディレクトリ)が存在するか
    func exists(path : String)->Bool {
        return self.fileManager.fileExistsAtPath(path)
    }
    
    // 有効な拡張子か
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
    
    // zip解凍
    func unzip(importFile : String, expandPath : String)->Bool {
        if (exists(expandPath)) {
            self.fileManager.removeItemAtPath(expandPath, error: nil)
        }
        return Main.unzipFileAtPath(importFile, toDestination: expandPath)
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
    // 内部ディレクトリを検索してopfファイルのパスを返却
    // Info: マルチDAISYはdiscinfo.html -> opf情報取得 -> xml情報取得
    // Info: テキストDAISYは直下のopf -> xml情報取得
    //
    func detectOpfPath(rootDir: String, didSuccess:((opfPath: String)->Void), didFailure:((errorCode: TTErrorCode)->Void))->Void {
        Log(NSString(format: "root_dir:%@", rootDir))
        
        if !(exists(rootDir)) {
            LogE(NSString(format: "Specified dircectory not found. [%@]", rootDir))
            didFailure(errorCode: TTErrorCode.OpfFileNotFound)
        }
        
        // 直下のファイルを展開
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
            /*** 不要
            if (isDir) {
                var path: String? = detectOpfPath(rootDir.stringByAppendingPathComponent(content))
                if path != nil {
                    return path
                }
                continue
            }
            */
            
            // マルチDAISYファイルの場合
            if content == DiscInfoManager.Const.kMultiDaisyInfoFile {
                var discInfoManager: DiscInfoManager = DiscInfoManager.sharedInstance
                var discInfoPath: String = rootDir.stringByAppendingPathComponent(content)
                discInfoManager.startParseDiscInfoFile(discInfoPath, didParseSuccess: { (discInfo) -> Void in
                    Log(NSString(format: "parse success. xml:%@", discInfo))
                    let opfPath: String = rootDir.stringByAppendingPathComponent(discInfo.opfFilePath)
                    if self.exists(opfPath) {
                        didSuccess(opfPath: opfPath)
                    } else {
                        LogE(NSString(format: "opf file not found. path:%@", opfPath))
                        didFailure(errorCode: TTErrorCode.OpfFileNotFound)
                    }
                    
                    }) { (errorCode) -> Void in
                        LogE(NSString(format: "Discinfo file not found. path:%@", discInfoPath))
                        didFailure(errorCode: errorCode)
                }
                return
            }
            
            // 拡張子をチェック
            if content.pathExtension.lowercaseString == OpfManager.Const.kOpfFileExtension {
                var opfPath: String = rootDir.stringByAppendingPathComponent(content)
                if exists(opfPath) {
                    didSuccess(opfPath: opfPath)
                } else {
                    LogE(NSString(format: "opf file not found. path:%@", opfPath))
                    didFailure(errorCode: TTErrorCode.OpfFileNotFound)
                }
                return
            }
        }
        
        LogE(NSString(format: "opf file not found. path:%@", rootDir))
        didFailure(errorCode: TTErrorCode.OpfFileNotFound)
    }
    
/*
    // XMLフォーマットのファイルの解析を開始
    func startParseXmlFormatFile(xmlFilePath: String,
        didParseSuccess: ((metaData: DCMetadata, xmlItem: ManifestItem)->Void),
        didParseFailure:((errorCode: TTErrorCode)->Void))->Void
    {
        self.didParseOpfSuccess = didParseSuccess
        self.didParseOpfFailure = didParseFailure
        
        let url: NSURL? = NSURL.fileURLWithPath(xmlFilePath)
        let parser: NSXMLParser? = NSXMLParser(contentsOfURL: url)
        
        if parser == nil {
            didParseFailure(errorCode: TTErrorCode.OpfFileNotFound)
            return
        }
        
        parser!.delegate = self
        
        parser!.parse()
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
*/
    
    //
    // XMLファイルの読み込み
    //
    func loadXmlFiles(xmlFilePaths:[String], saveDir: String)->String {
        Log(NSString(format: "xml_file_path:%@", xmlFilePaths))
        if xmlFilePaths.count == 0 {
            LogE(NSString(format: "No xml files. [%@]", xmlFilePaths))
            return ""
        }
        
        startLoadingSound()
        
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
            stopLoadingSound()
            return ""
        }
        
        stopLoadingSound()
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
    
    
    //
    // MARK: Private
    //
    
    // ローディング中のサウンド再生
    private func startLoadingSound()->Void {
        LogM("register timer")
        let queue = dispatch_queue_create("tdtalk2", nil)
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
    
    // ローディング中のサウンド停止
    private func stopLoadingSound()->Void {
        if sound_source != nil {
            dispatch_source_cancel(sound_source!)
        }
    }
    
    
    
    //
    // MARK: NSXMLParserDelegate
    //
    
    // ファイルの読み込みを開始
    func parserDidStartDocument(parser: NSXMLParser) {
        LogM("--- start parse.")
    }
    
    // 要素の開始タグを読み込み
    func parser(parser: NSXMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [NSObject : AnyObject])
    {
        Log(NSString(format: " - found element:[%@] attr[%@]", elementName, attributeDict))
        
        if elementName == DCMetadataTag.DC_Metadata.rawValue {
            self.isInDcMetadata = true
        } else if self.isInDcMetadata {
            self.currentElement = elementName
        }
        
        if elementName == ManifestTag.Manifest.rawValue {
            self.isInManifest = true
            
        } else if self.isInManifest {
            if elementName == ManifestTag.Item.rawValue {
                // xmlファイル情報のみ取得
                var attr: String = attributeDict[ManifestItemAttr.Id.rawValue] as! String
                if attr == "xml" {
                    self.xmlItem.id = attributeDict[ManifestItemAttr.Id.rawValue] as! String
                    self.xmlItem.href = attributeDict[ManifestItemAttr.Href.rawValue] as! String
                    self.xmlItem.mediaType = attributeDict[ManifestItemAttr.MediaType.rawValue] as! String
                }
            }
        }
        
    }
    
    // valueを読み込み
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        Log(NSString(format: " - found value:[%@] current_elem:%@", string!, self.currentElement))
        
        if self.isInDcMetadata {
            switch self.currentElement {
            case DCMetadataTag.DC_Identifier.rawValue:
                self.metaData.identifier = string!
                break
            case DCMetadataTag.DC_Title.rawValue:
                self.metaData.title = string!
                break
            case DCMetadataTag.DC_Publisher.rawValue:
                self.metaData.publisher = string!
                break
            case DCMetadataTag.DC_Subject.rawValue:
                self.metaData.subject = string!
                break
            case DCMetadataTag.DC_Date.rawValue:
                self.metaData.date = string!
                break
            case DCMetadataTag.DC_Creator.rawValue:
                self.metaData.creator = string!
                break
            case DCMetadataTag.DC_Language.rawValue:
                self.metaData.language = string!
                break
            case DCMetadataTag.DC_Format.rawValue:
                self.metaData.format = string!
                break
            default:
                break
            }
        }
        
    }
    
    // 要素の終了タグを読み込み
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        Log(NSString(format: " - found element:[%@]", elementName))
        
        if self.isInDcMetadata {
            if elementName == DCMetadataTag.DC_Metadata.rawValue {
                self.isInDcMetadata = false
            }
            self.currentElement = ""
        }
        if self.isInManifest {
            if elementName == ManifestTag.Manifest.rawValue {
                self.isInManifest = false
            }
        }
    }

    // ファイルの読み込みを終了
    func parserDidEndDocument(parser: NSXMLParser) {
        LogM("--- end parse.")
        
        if didParseOpfSuccess != nil {
            self.didParseOpfSuccess!(metaData: self.metaData, xmlItem: self.xmlItem)
        }
    }
    
    
}