//
//  NSObject+Name.swift
//  gat
//
//  Created by HungTran on 3/26/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

/**Lấy tên của Object để thông báo lỗi cho tiện*/
extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
}
