//
//  Book.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

class BookInfo {
    var editionId: Int = 0
    var bookId: Int = 0
    var title: String = ""
    var author: String = ""
    var descriptionBook: String = ""
    var rateAvg: Double = 0.0
    var imageId: String = ""
    var isbn13: String = ""
    var isbn10: String = ""
    var saving: Bool = false
    var totalPage: Int = 0
    var instanceCount: Int = 0
    
    init() {
        
    }
    
    init(editionId: Int, bookId: Int, title: String, author: String, rateAvg: Double, imageId: String) {
        self.editionId = editionId
        self.bookId = bookId
        self.title = title
        self.author = author
        self.rateAvg = rateAvg
        self.imageId = imageId
    }
    
    func parse(json: JSON) {
        self.editionId = json["editionId"].int ?? 0
        self.bookId = json["bookId"].int ?? 0
        self.title = json["title"].string ?? ""
        self.author = json["author"].string ?? ""
        self.descriptionBook = json["descriptionBook"].string ?? ""
        self.rateAvg = json["rateAvg"].double ?? 0.0
        self.imageId = json["imageId"].string ?? ""
        self.totalPage = json["numberOfPage"].int ?? 0
        print("TOTALLLLLLLLL:\(totalPage)")
    }
}

extension BookInfo: ObjectConvertable {
    typealias Object = BookInfoObject
    
    func asObject() -> BookInfoObject {
        let object = BookInfoObject()
        object.editionId = self.editionId
        object.bookId = self.bookId
        object.title = self.title
        object.author = self.author
        object.descriptionBook = self.descriptionBook
        object.rateAvg = self.rateAvg
        object.imageId = self.imageId
        object.saving = self.saving
        object.totalPage = self.totalPage
        return object
    }
}

class BookInfoObject: Object {
    @objc dynamic var editionId: Int = 0
    @objc dynamic var bookId: Int = 0
    @objc dynamic var title: String = ""
    @objc dynamic var author: String = ""
    @objc dynamic var descriptionBook: String = ""
    @objc dynamic var rateAvg: Double = 0.0
    @objc dynamic var imageId: String = ""
    @objc dynamic var saving: Bool = false
    @objc dynamic var totalPage:Int = 0
    
    override class func primaryKey() -> String? {
        return "editionId"
    }
}

extension BookInfoObject: DomainConvertable {
    typealias Domain = BookInfo
    
    func asDomain() -> BookInfo {
        let domain = BookInfo()
        domain.editionId = self.editionId
        domain.bookId = self.bookId
        domain.title = self.title
        domain.author = self.author
        domain.descriptionBook = self.descriptionBook
        domain.rateAvg = self.rateAvg
        domain.imageId = self.imageId
        domain.saving = self.saving
        domain.totalPage = self.totalPage
        return domain
    }
}

extension BookInfoObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        return self.editionId
    }
}
