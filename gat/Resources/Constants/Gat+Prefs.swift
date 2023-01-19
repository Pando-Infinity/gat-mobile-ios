//
//  Constants.swift
//  gat
//
//  Created by HungTran on 6/12/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

struct Gat {

}

extension Gat {
    /**Prefs: Lưu các đường dẫn điều hướng tới các màn hình cài đặt.*/
    struct Prefs {
        static let OPEN_PRIVACY = UIApplication.openSettingsURLString
    }
}


class LanguageHelper {
    class var language: LanguageSupport {
        return LanguageSupport(rawValue: UserDefaults.standard.string(forKey: "language") ?? "") ?? .english
    }
    
    class var bundle: Bundle {
        let code = language == .english ? "Base" : language.rawValue
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) else { return .main }
        return bundle
    }
    
    static let changeEvent: PublishSubject<()> = .init()
}
