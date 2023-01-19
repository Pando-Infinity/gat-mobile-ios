//
//  Realm+SafeWrite.swift
//  gat
//
//  Created by HungTran on 4/29/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

extension Realm {
    public func safeWrite(_ block: (() throws -> Void)) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
}
