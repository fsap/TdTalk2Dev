//
//  DiscInfoManager.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

class DiscInfoManager: NSObject, NSXMLParserDelegate {
    
    // 定数
    struct Const {
        static let kMultiDaisyInfoFile: String = "discinfo.html"
    }
    
    private var didParseSuccess: ((discInfo: DiscInfo)->Void)?
    private var didParseFailure: ((errorCode: TTErrorCode)->Void)?
    private var discInfo: DiscInfo
    private var isInBody: Bool
    private var currentElement: String


    class var sharedInstance : DiscInfoManager {
        struct Static {
            static let instance : DiscInfoManager = DiscInfoManager()
        }
        return Static.instance
    }
    
    override init() {
        self.didParseSuccess = nil
        self.didParseFailure = nil
        self.discInfo = DiscInfo()
        self.isInBody = false
        self.currentElement = ""
        
        super.init()
    }
    
    func startParseDiscInfoFile(discinfoFilePath: String,
        didParseSuccess: ((discInfo: DiscInfo)->Void),
        didParseFailure:((errorCode: TTErrorCode)->Void))->Void
    {
        self.didParseSuccess = didParseSuccess
        self.didParseFailure = didParseFailure
        
        let url: NSURL? = NSURL.fileURLWithPath(discinfoFilePath)
        let parser: NSXMLParser? = NSXMLParser(contentsOfURL: url)
        
        if parser == nil {
            didParseFailure(errorCode: TTErrorCode.OpfFileNotFound)
            return
        }
        
        parser!.delegate = self
        
        parser!.parse()
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
        
        if elementName == DiscinfoTag.Body.rawValue {
            self.isInBody = true
        } else if self.isInBody {
            self.currentElement = elementName
        }
        
        if elementName == DiscinfoTag.Body.rawValue {
            self.isInBody = true
            
        } else if self.isInBody {
            if elementName == DiscinfoTag.A.rawValue {
                // xmlファイル情報のみ取得
                self.discInfo.href = attributeDict[DiscinfoAttr.Href.rawValue] as! String
            }
        }
    }
    
    // valueを読み込み
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        Log(NSString(format: " - found value:[%@] current_elem:%@", string!, self.currentElement))
        
    }
    
    // 要素の終了タグを読み込み
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        Log(NSString(format: " - found element:[%@]", elementName))
        
        if self.isInBody {
            if elementName == DiscinfoTag.A.rawValue {
                self.isInBody = false
            }
            self.currentElement = ""
        }
    }
    
    // ファイルの読み込みを終了
    func parserDidEndDocument(parser: NSXMLParser) {
        LogM("--- end parse.")
        
        if didParseSuccess != nil {
            self.didParseSuccess!(discInfo: self.discInfo)
        }
    }
    

}