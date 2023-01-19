//
//  LanguageSupport.swift
//  gat
//
//  Created by jujien on 2/13/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation

enum LanguageSupport: String, CaseIterable {
    case english = "en"
    case vietnamese = "vi"
    case japanese = "ja"
}

extension LanguageSupport {
    var name: String {
        switch self {
        case .english:
            return "English"
        case .vietnamese:
            return "Tiếng Việt"
        case .japanese:
            return "日本語"
        }
    }
    
    var identifier: String {
        switch self {
        case .english:
            return "en_US"
        case .vietnamese:
            return "vi_VN"
        case .japanese:
            return "ja_JP"
        }
    }
}
