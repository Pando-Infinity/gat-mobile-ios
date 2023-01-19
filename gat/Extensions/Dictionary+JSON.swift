//
//  Dictionary+JSON.swift
//  gat
//
//  Created by HungTran on 7/7/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
extension Dictionary {
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
}
