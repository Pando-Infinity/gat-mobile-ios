//
//  Bookstop.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

class BookstopRealm: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var user: User?
    @objc dynamic var status: Int = -1
    @objc dynamic var name: String = ""
    @objc dynamic var imageId: String = ""
    @objc dynamic var address: String = ""
    @objc dynamic var sharingCount = 0
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    static func parse(json: JSON) -> [BookstopRealm] {
        
        return json.array?.compactMap({ (json) -> BookstopRealm? in
            guard let id = json["bookstopId"].int else {
                return nil
            }
            if let bookstop = try? Realm().object(ofType: BookstopRealm.self, forPrimaryKey: id) {
                try? Realm().safeWrite {
                    bookstop?.name = json["bookstopName"].string ?? ""
                    bookstop?.imageId = json["bookstopImageId"].string ?? ""
                    bookstop?.address = json["bookstopAddress"].string ?? ""
                    bookstop?.sharingCount = json["sharingCount"].int ?? 0
                }
                return bookstop 
            } else {
                let bookstop = BookstopRealm()
                bookstop.id = json["bookstopId"].int ?? 0
                bookstop.name = json["bookstopName"].string ?? ""
                bookstop.imageId = json["bookstopImageId"].string ?? ""
                bookstop.address = json["bookstopAddress"].string ?? ""
                bookstop.sharingCount = json["sharingCount"].int ?? 0
                return bookstop
            }
        }) ?? []
    }
}
