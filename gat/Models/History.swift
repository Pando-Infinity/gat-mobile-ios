//
//  History.swift
//  gat
//
//  Created by Vũ Kiên on 27/06/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

enum HistoryType: Int {
    case book = 0
    case author = 1
    case user = 2
}

class History {
    var id: String = ""
    var text: String = ""
    var date: Date = Date()
    var type: HistoryType = .book
    
    init(id: String, text: String, timeInterval: TimeInterval, type: HistoryType) {
        self.id = id
        self.text = text
        self.date = Date(timeIntervalSince1970: timeInterval)
        self.type = type
    }
    
    static func parse(json: JSON, type: HistoryType) -> [History] {
        return json["data"]["resultInfo"].array?.compactMap({ (json) -> History? in
            guard let text = json["keyword"].string else {
                return nil
            }
            return History(id: UUID().uuidString, text: text, timeInterval: Date().timeIntervalSince1970, type: type)
        }) ?? []
    }
}

extension History: ObjectConvertable {
    typealias Object = HistoryObject
    
    func asObject() -> HistoryObject {
        let object = HistoryObject()
        object.id = self.id
        object.text = self.text
        object.date = self.date
        object.type = self.type.rawValue
        return object
    }
    
}

extension History: CustomStringConvertible {
    var description: String {
        return "{\n\tid = \(self.id),\n\ttext = \(self.text),\n\tdate = \(self.date),\n\ttype = \(self.type)\n}"
    }
    
    
}


class HistoryObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var text: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var type: Int = 0
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
//    static func create(id: String, text: String, date: TimeInterval, type: Int) -> HistoryObject {
//        let history = HistoryObject()
//        history.id = id
//        history.text = text
//        history.date = date
//        history.type = type
//        return history
//    }
//
//    static func parse(_ json: JSON, type: Int) -> [HistoryObject] {
//        let data = json["data"]
//        guard let resultInfo = data["resultInfo"].array else {
//            return []
//        }
//        let histories = resultInfo.flatMap { (json) -> HistoryObject? in
//            guard let text = json["keyword"].string else {
//                return nil
//            }
//
//            return HistoryObject.create(id: UUID().uuidString, text: text, date: Date().timeIntervalSince1970, type: type)
//        }
//        return histories
//    }
}

extension HistoryObject: DomainConvertable {
    typealias Domain = History
    
    func asDomain() -> History {
        return History(id: self.id, text: self.text, timeInterval: self.date.timeIntervalSince1970, type: HistoryType(rawValue: self.type) ?? .book)
    }
    
}
