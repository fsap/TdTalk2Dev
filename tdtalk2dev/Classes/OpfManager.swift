//
//  OpfManager.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

class OpfManager: NSObject, NSXMLParserDelegate {
    
    
    private var didParseSuccess: ((opf: OPF)->Void)?
    private var didParseFailure: ((errorCode: TTErrorCode)->Void)?
    private var opf: OPF
    private var isInDcMetadata: Bool
    private var isInManifest: Bool
    private var currentElement: String
    
    
    class var sharedInstance : OpfManager {
        struct Static {
            static let instance : OpfManager = OpfManager()
        }
        return Static.instance
    }
    
    override init() {
        self.didParseSuccess = nil
        self.didParseFailure = nil
        self.opf = OPF()
        self.isInDcMetadata = false
        self.isInManifest = false
        self.currentElement = ""
        
        super.init()
    }
    
    func startParseOpfFile(opfFilePath: String,
        didParseSuccess: ((opf: OPF)->Void),
        didParseFailure:((errorCode: TTErrorCode)->Void))->Void
    {
        self.didParseSuccess = didParseSuccess
        self.didParseFailure = didParseFailure
        
        let url: NSURL? = NSURL.fileURLWithPath(opfFilePath)
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
                    self.opf.manifestItem.id = attributeDict[ManifestItemAttr.Id.rawValue] as! String
                    self.opf.manifestItem.href = attributeDict[ManifestItemAttr.Href.rawValue] as! String
                    self.opf.manifestItem.mediaType = attributeDict[ManifestItemAttr.MediaType.rawValue] as! String
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
                self.opf.dcMetadata.identifier = string!
                break
            case DCMetadataTag.DC_Title.rawValue:
                self.opf.dcMetadata.title = string!
                break
            case DCMetadataTag.DC_Publisher.rawValue:
                self.opf.dcMetadata.publisher = string!
                break
            case DCMetadataTag.DC_Subject.rawValue:
                self.opf.dcMetadata.subject = string!
                break
            case DCMetadataTag.DC_Date.rawValue:
                self.opf.dcMetadata.date = string!
                break
            case DCMetadataTag.DC_Creator.rawValue:
                self.opf.dcMetadata.creator = string!
                break
            case DCMetadataTag.DC_Language.rawValue:
                self.opf.dcMetadata.language = string!
                break
            case DCMetadataTag.DC_Format.rawValue:
                self.opf.dcMetadata.format = string!
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
        
        if self.didParseSuccess != nil {
            self.didParseSuccess!(opf: opf)
        }
    }
    
}