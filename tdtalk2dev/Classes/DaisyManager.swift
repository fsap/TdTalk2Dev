//
//  DaisyManager.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit

enum DaisyStandards: CGFloat {
    case Version2_02 = 2.02
    case Version3 = 3
}

struct DaisyStandard2_02 {
    static let Version: CGFloat = 2.02
    static let MetadataFileName:String = "ncc.html"
    static let IndexFileName:String = "ncc.html"
}

struct DaisyStandard3 {
    static let Version: CGFloat = 3
    static let MetadataFileExtension:String = "opf"
    static let IndexFileExtension:String = "ncx"
}


class DaisyManager: NSObject {
    
    var daisies: [Daisy]
    
    override init() {
        daisies = []
    }
    
    class var sharedInstance : DaisyManager {
        struct Static {
            static let instance : DaisyManager = DaisyManager()
        }
        return Static.instance
    }
    
    ///
    /// Daisy規格のチェック
    /// :param: String チェックするディレクトリ(zip展開済み)
    /// :param: Closure 処理に成功した時のクロージャを定義
    /// :param: Closure 処理に失敗した時のクロージャを定義
    ///
    func detectDaisyStandard(targetFilePath: String, didSuccess:((version: CGFloat)->Void), didFailure:((errorCode: TTErrorCode)->Void)) {
        
        // マルチDAISYか確認するためにdiscinfoをサーチ
        
    }
    
    //
    // Daisyファイルの取り込み
    //
    func importDaisy(
        targetFilePath :String,
        version: CGFloat,
        didSuccess:((books: [BookEntity])->Void),
        didFailure:((errorCode: TTErrorCode)->Void)
    )
    {
        
    }
}