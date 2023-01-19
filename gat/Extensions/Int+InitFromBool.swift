//
//  Int+InitFromBool.swift
//  gat
//
//  Created by HungTran on 6/4/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Int {
    init(_ bool:Bool) {
        self = bool ? 1 : 0
    }
}
