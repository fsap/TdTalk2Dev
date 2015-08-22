//
//  DiscInfo.swift
//  tdtalk2dev
//
//  Created by 藤原修市 on 2015/08/18.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation

class DiscInfo: NSObject {
    
    var href: String
    
    override init() {
        self.href = ""
        super.init()
    }
    
    init(href: String) {
        self.href = href
        super.init()
    }
}