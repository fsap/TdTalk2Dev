//
//  Constants.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation


struct Constants {
    /*
        Daisy規格関連
    */
    // マルチDAISY情報ファイル
    static let kMultiDaisyInfoFile: String = "discinfo.html"
    
    /*
        ファイル操作関連
    */
    // 取り込み可能な拡張子
    static let kImportableExtensions: [String] = ["zip", "exe"]
    // 他アプリからエクスポートされたファイルの格納場所
    static let kInboxDocumentPath: String = "Documents/Inbox"
    // 一時作業用ディレクトリ
    static let kTmpDocumentPath: String = "tmp/"
    // 図書ファイルとして保存するディレクトリ
    static let kSaveDocumentPath: String = "Library/Books"


}