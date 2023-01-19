//
//  Config.swift
//  gat
//
//  Created by HungTran on 2/23/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
typealias swiftJSON = JSON

class AppConfig {
    static let sharedConfig = AppConfig()
    
    var completPopupChallenge: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "completPopupChallenge")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "completPopupChallenge")
        }
    }
    
    /**Trả về giá trị cấu hình từ **Property File** `Resources/AppConfig.plist`.
    Ex. `let api_url: String = Config.sharedConfig.get("api_url")`
    - parameter key:  Key tương ứng trong Property File
    - returns: Genertic Type*/
    func get<T>(_ key: String) -> T {
        let path: String = Bundle.main.path(forResource: "AppConfig", ofType: "plist")!
        let file: NSDictionary = NSDictionary(contentsOfFile: path)!
        return file.object(forKey: key) as! T
    }
    
    func getUrl(_ key: String, _ parameter: String) -> String {
        var url: String = self.get(key)
        url += parameter
        return url
    }
    
    func setUrlImage(id: String, size: SizeImage = .s) -> String {
        var urlString: String = self.config(item: "api_url")!
        urlString += "common/get_image/\(id.isEmpty ? "33328625223" : id)?size=\(size.rawValue)"
        return urlString
    }
    
    func getData<T>(key: String, item: String,  index: Int? = nil) -> T {
        let dicts: NSDictionary = self.get(key)
        let arrays = dicts.object(forKey: item)
        if let index = index {
            let data = (arrays as! NSArray).object(at: index)
            return data as! T
        } else {
            return arrays as! T
        }
    }
    
    func getUrlFile(_ file: String, withExtension: String) -> URL? {
        return Bundle.main.url(forResource: file, withExtension: withExtension)
    }
    
    func convertToDate(from string: String, format: String = "yyyy-MM-dd") -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: string) ?? Date()
    }
    
    func stringFormatter(from date: Date, format: String = "yyyy-MM-dd") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: LanguageHelper.language.identifier)
        return dateFormatter.string(from: date)
    }
    
    func calculatorDay(date: Date) -> String {
        let currentDate = Date().timeIntervalSince1970
        let timeInterval = date.timeIntervalSince1970
        if ((currentDate - timeInterval) / 31536000.0).rounded(.down) >= 1 {
            return String(format: Gat.Text.Date.YEARS.localized(), Int(((currentDate - timeInterval) / 31536000.0).rounded(.down)))
        } else if ((currentDate - timeInterval) / 2592000.0).rounded(.down) >= 1 {
            return String(format: Gat.Text.Date.MONTHS.localized(), Int(((currentDate - timeInterval) / 2592000.0).rounded(.down)))
        } else if ((currentDate - timeInterval) / 604800.0).rounded(.down) >= 1 {
            return String(format: Gat.Text.Date.WEEKS.localized(), Int(((currentDate - timeInterval) / 604800.0).rounded(.down)))
        } else if ((currentDate - timeInterval) / 86400.0).rounded(.down) >= 1 {
            return String(format: Gat.Text.Date.DAYS.localized(), Int(((currentDate - timeInterval) / 86400.0).rounded(.down)))
        } else if ((currentDate - timeInterval) / 3600.0).rounded(.down) >= 1 {
            return String(format: Gat.Text.Date.HOURS.localized(), Int(((currentDate - timeInterval) / 3600.0).rounded(.down)))
        } else if ((currentDate - timeInterval) / 60.0).rounded(.down) >= 1 {
            return String(format: Gat.Text.Date.MINUTES.localized(), Int(((currentDate - timeInterval) / 60.0).rounded(.down)))
        } else {
            return String(format: Gat.Text.Date.SECONDS.localized(), Int(currentDate - timeInterval) % 60)
        }
    }
    
    func stringDistance(_ distance: Double) -> String {
        var distance = distance
        if distance >= 1000 {
            distance /= 1000
            return String(format: "%.2f km", distance)
        } else {
            return "\(Int(distance)) m"
        }
    }
    
    /**Dọn dẹp dữ liệu của User*/
    func clearUserData() {
    }
    
    func uuid() -> String {
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            return uuid;
        } else {
            return "";
        }
    }
    
    func config(item: String) -> String? {
        Bundle.main.infoDictionary?[item] as? String 
    }
}

//Size anh lay ve
enum SizeImage: String {
    case s //hình vuông nhỏ 75x75
    case q //large square 150x150
    case t //ảnh thu nhỏ, cạnh dài nhất là 100
    case m //nhỏ, cạnh dài nhất là 240
    case n //small, 320 on longest side
    case z //trung bình 640, 640 trên cạnh dài nhất
    case c //trung bình 800, 800 trên cạnh dài nhất
    case b //lớn, 1024 trên cạnh dài nhất*
    case h //lớn 1600, 1600 ở cạnh dài nhất
    case k //lớn 2048, 2048 ở cạnh dài nhất
    case o //ảnh gốc, định dạng jpg, gif hoặc png, tùy vào định dạng nguồn
}


