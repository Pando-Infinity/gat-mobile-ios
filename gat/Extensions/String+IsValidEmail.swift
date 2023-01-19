//
//  String+IsValidEmail.swift
//  gat
//
//  Created by HungTran on 5/18/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension String {
    func isValidEmail() -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)
    }
    
    /**
     test@gmail.com => te**@gmail.com
     1@gmail.com
     */
    func secureEmail() -> String {
        if let prefix = self.components(separatedBy: "@").first, let postfix = self.components(separatedBy: "@").last {
            let firstHalfPrefix = prefix.count / 2
            let lastHalfPrefix = prefix.count - firstHalfPrefix
            let secretPart = String(repeating: "*", count: lastHalfPrefix)
            return prefix.substring(to: firstHalfPrefix) + secretPart + "@" + postfix
        } else {
            return ""
        }
    }
    
    var isNumber : Bool {
        get{
            return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        }
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex..<endIndex)
    }
    
    func stringSize(text: String, with attributes: [NSAttributedString.Key: Any]) -> CGSize? {
        guard let range = self.range(of: text) else {
            return nil
        }
        let size = (self.substring(with: range) as NSString).size(withAttributes: attributes)
        return size
    }
    
    func localized(bundle: Bundle = LanguageHelper.bundle, tableName: String? = nil) -> String {
        return NSLocalizedString(self, tableName: tableName, bundle: bundle, comment: "")
    }
    
//    func findMentionText() -> [String] {
//        var arr_hasStrings:[String] = []
//        let regex = try? NSRegularExpression(pattern: "(#[a-zA-Z0-9_\\p{Arabic}\\p{N}]*)", options: [])
//        if let matches = regex?.matches(in: self, options:[], range:NSMakeRange(0, self.count)) {
//            for match in matches {
//                arr_hasStrings.append(NSString(string: self).substring(with: NSRange(location:match.range.location, length: match.range.length )))
//            }
//        }
//        return arr_hasStrings
//    }
    
    func date(format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self)
    }
}
