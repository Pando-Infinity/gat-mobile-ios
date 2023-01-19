//
//  UserPublic.swift
//  gat
//
//  Created by Vũ Kiên on 10/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation

class UserPublic {
    var profile: Profile
    var reviewCount = 0
    var sharingCount = 0
    var articleCount = 0
    var distance: Double = 0.0
    var activeFlag: Bool = false
    var followMe: Bool = false
    var followedByMe: Bool = false
    var followingCount = 0
    var invited:Bool = false
    
    init() {
        self.profile = Profile()
    }
}
