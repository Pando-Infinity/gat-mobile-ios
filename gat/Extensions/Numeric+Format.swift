//
//  Numeric+Format.swift
//  gat
//
//  Created by HungTran on 3/23/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

protocol Formattable {
    func format(pattern: String) -> String
}

extension Formattable where Self: CVarArg {
    func format(pattern: String) -> String {
        return String(format: pattern, arguments: [self])
    }
}

extension Int: Formattable { }
extension Double: Formattable { }
extension Float: Formattable { }

extension Double {
    func currency(locale: Locale = .current) -> String? {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        return currencyFormatter.string(from: NSNumber(floatLiteral: self))
    }
}
