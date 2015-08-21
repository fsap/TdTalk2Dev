//
//  Daisy.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/21.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit

class Daisy: NSObject {
    
    // Daisyバージョン
    var version: CGFloat
    // メタデータ
    var metadadta: DCMetadata
    // 目次情報
    var navigation: Navigation
    

    override init() {
        self.version = 2.02
        self.metadadta = DCMetadata()
        self.navigation = Navigation()
    }
}