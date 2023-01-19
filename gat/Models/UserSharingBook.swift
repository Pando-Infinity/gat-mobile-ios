//
//  UserSharingBook.swift
//  gat
//
//  Created by Vũ Kiên on 29/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation

class UserSharingBook {
    var profile: Profile
    var bookInfo: BookInfo
    var request: BookRequest?
    var availableStatus: Bool = false
    var distance: Double = 0.0
    var activeFlag: Bool = false
    var sharingCount = 0
    var reviewCount = 0
    
    init() {
        self.bookInfo = BookInfo()
        self.profile = Profile()
    }
}
