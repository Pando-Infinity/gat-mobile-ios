//
//  Message.swift
//  gat
//
//  Created by Vũ Kiên on 15/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import Firebase
import SwiftyJSON

/*
 {
   "965782" : "2019-11-09T14:43:04+0700",
   "38" : "2019-11-09T14:43:04+0700"
 }
 */

enum MessageType: Int {
    case text = 1
    case profile = 2
    case book = 3
    case review = 4
}

class Message {
    var messageId: String = ""
    var user: Profile?
    var type: MessageType
    var content: String = ""
    var description: String = ""
    var sendDate: Date = Date()
    var readTime: [String: Date] = [:]
    
    var isRead: Bool {
        guard let user = Repository<UserPrivate, UserPrivateObject>.shared.get() else { return false }
        return self.readTime.filter { $0.key == "\(user.id)" }.first != nil
    }
    
    var data: [String: Any] {
        let dict: [String: Any] = [
            "type": self.type.rawValue,
            "content": self.content,
            "description": self.description,
            "timestamp": self.sendDate,
            "sender": self.user!.id,
            "read_timestamp": self.readTime
        ]
        return dict
    }
    
    init() {
        self.user = Profile()
        self.type = .text
    }
    
    init(dict: [String: Any]) {
        self.content = dict["content"] as? String ?? ""
        self.user = Profile()
        self.user?.id = dict["sender"] as? Int ?? 0
        self.sendDate = (dict["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.type = MessageType(rawValue: (dict["type"] as? Int) ?? 1) ?? .text
        self.description = dict["description"] as? String ?? ""
        self.readTime = (dict["read_timestamp"] as? [String: Timestamp])?.mapValues { $0.dateValue() } ?? [:]
        self.messageId = "\(Int64(self.sendDate.timeIntervalSince1970 * 1000.0))_\(self.user!.id)"
    }
    
    init(messageId: String, user: Profile?, type: MessageType, content: String, description: String, sendDate: Date, readTime: [String: Date]) {
        self.messageId = messageId
        self.user = user
        self.description = description
        self.sendDate = sendDate
        self.type = type
        self.content = content
        self.readTime = readTime
    }
}

extension Message: ObjectConvertable {
    typealias Object = MessageObject
    
    func asObject() -> MessageObject {
        let object = MessageObject()
        object.messageId = self.messageId
        object.user = self.user?.asObject()
        object.content = self.content
        object.type = self.type.rawValue
        object.descriptionText = self.description
        object.sendDate = self.sendDate
        if !self.readTime.isEmpty {
            object.readTime = JSON(self.readTime.mapValues { AppConfig.sharedConfig.stringFormatter(from: $0, format: "yyyy-MM-dd'T'HH:mm:ssZ")}).rawString() ?? ""
        }
        object.isRead = self.isRead
        return object
    }
    
    
}

class MessageObject: Object {
    @objc dynamic var messageId: String = ""
    @objc dynamic var user: ProfileObject?
    @objc dynamic var type: Int = 1
    @objc dynamic var content: String = ""
    @objc dynamic var descriptionText: String = ""
    @objc dynamic var sendDate: Date = Date()
    @objc dynamic var readTime: String = ""
    @objc dynamic var isRead: Bool = false
    
    override class func primaryKey() -> String? {
        return "messageId"
    }
}

extension MessageObject: DomainConvertable {
    typealias Domain = Message
    
    func asDomain() -> Message {
        var readTime: [String: Date] = [:]
        if !self.readTime.isEmpty {
            let json = try! JSONSerialization.jsonObject(with: self.readTime.data(using: .utf8)!, options: []) as! [String: String]
            readTime = json.mapValues({ (value) -> Date in
                return AppConfig.sharedConfig.convertToDate(from: value, format: "yyyy-MM-dd'T'HH:mm:ssZ")
            })
            
        }
        return .init(messageId: self.messageId, user: self.user?.asDomain(), type: MessageType(rawValue: self.type) ?? .text, content: self.content, description: self.descriptionText, sendDate: self.sendDate, readTime: readTime)
    }
}

extension MessageObject: PrimaryValueProtocol {
    typealias K = String
    
    func primaryValue() -> String {
        return self.messageId
    }
}

