//
//  ReadingStatus.swift
//  gat
//
//  Created by Vũ Kiên on 21/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

/**Hung them
 + 0: Readed - đã đọc
 + 1: Reading - đang đọc
 + 2: To read - sẽ đọc*/
enum StatusReadBook: Int {
    case remove = -1
    case reading = 1
    case toRead = 2
    case read = 0
}

class ReadingStatus {
    var readingId: Int?
    var bookInfo: BookInfo?
    var status: StatusReadBook = .remove
}

extension ReadingStatus: ObjectConvertable {
    typealias Object = ReadingStatusObject
    
    func asObject() -> ReadingStatusObject {
        let object = ReadingStatusObject()
        object.readingId.value = self.readingId
        object.bookInfo = self.bookInfo?.asObject()
        object.status = self.status.rawValue
        return object
    }
    
    
}

class ReadingStatusObject: Object {
    let readingId = RealmOptional<Int>()
    @objc dynamic var bookInfo: BookInfoObject?
    @objc dynamic var status: Int = -1
    
    override static func primaryKey() -> String {
        return "readingId"
    }
}

extension ReadingStatusObject: DomainConvertable {
    typealias Domain = ReadingStatus
    
    func asDomain() -> ReadingStatus {
        let domain = ReadingStatus()
        domain.readingId = self.readingId.value
        domain.bookInfo = self.bookInfo?.asDomain()
        domain.status = StatusReadBook(rawValue: self.status) ?? .remove
        return domain
    }
    
    
}
