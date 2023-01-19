//
//  DateTime+Format.swift
//  gat
//
//  Created by HungTran on 4/29/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Date {
    
    func format() -> String {
        let calendar = NSCalendar.current
        let date = calendar.component(.day, from: self as Date)
        let month = calendar.component(.month, from: self as Date)
        let year = calendar.component(.year, from: self as Date)
        
        let lang = NSLocalizedString("Accept-Language", comment: "");
        if lang == "vi" {
            return  "\(date) tháng \(month) năm \(year)"
        } else {
            let monthDictionary: [Int: String] = [
                1: "January",
                2: "February",
                3: "March",
                4: "April",
                5: "May",
                6: "June",
                7: "July",
                8: "August",
                9: "September",
                10: "October",
                11: "November",
                12: "December"
            ]
            return monthDictionary[month]! + " \(date), \(year)";
        }
        
    }
    
    func string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

extension NSDate {
    func toDate() -> Date {
        return Date(timeIntervalSince1970: self.timeIntervalSince1970)
    }
}
