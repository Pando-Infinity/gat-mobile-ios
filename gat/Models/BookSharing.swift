//
//  BookSharing.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

class BookSharing {
    var id: Int = 0
    var info: BookInfo?
    var rateCount: Int = 0
    var sharingCount: Int = 0
    var reviewCount: Int = 0

    init() {
        self.info = BookInfo()
    }
}

extension BookSharing: ObjectConvertable {
    typealias Object = BookSharingObject
    
    func asObject() -> BookSharingObject {
        let object = BookSharingObject()
        object.id = self.id
        object.info = self.info?.asObject()
        object.rateCount = self.rateCount
        object.sharingCount = self.sharingCount
        object.reviewCount = self.reviewCount
        return object
    }
    
    
}

class BookSharingObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var info: BookInfoObject?
    @objc dynamic var rateCount: Int = 0
    @objc dynamic var sharingCount: Int = 0
    @objc dynamic var reviewCount: Int = 0
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}

extension BookSharingObject: DomainConvertable {
    typealias Domain = BookSharing
    
    func asDomain() -> BookSharing {
        let domain = BookSharing()
        domain.id = self.id
        domain.info = self.info?.asDomain()
        domain.rateCount = self.rateCount
        domain.sharingCount = self.sharingCount
        domain.reviewCount = self.reviewCount
        return domain
    }
    
}

extension BookSharingObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        return self.id
    }
}
