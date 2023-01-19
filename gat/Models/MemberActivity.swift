//
//  MemberActivity.swift
//  gat
//
//  Created by Vũ Kiên on 16/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON

class MemberActivity {
    var activityId: Int = 0
    var user: Profile
    var book: BookInfo
    var bookstop: Bookstop
    var status: Status?
    var activityType: Int = 0
    var activityTime: Date = Date()
    
    init(bookstop: Bookstop) {
        self.bookstop = bookstop
        self.user = Profile()
        self.book = BookInfo()
    }
    
    init() {
        self.book = BookInfo()
        self.user = Profile()
        self.bookstop = Bookstop()
    }
}

extension MemberActivity {
    enum Status: Int {
        case borrow = 1
        case `return` = 2
    }
}
