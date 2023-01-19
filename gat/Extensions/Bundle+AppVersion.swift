//
//  Bundle+AppVersion.swift
//  gat
//
//  Created by HungTran on 6/5/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
