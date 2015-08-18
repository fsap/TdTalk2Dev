//
//  DiscInfo.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

enum DiscinfoTag: String {
    case Body = "body"
    case A = "a"
}

enum DiscinfoAttr: String {
    case Href = "href"
}

class DiscInfo: NSObject {
    
    var href: String
    
    override init() {
        self.href = ""
        super.init()
    }
}