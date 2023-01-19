//
//  GroupMessage.swift
//  gat
//
//  Created by Vũ Kiên on 15/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

class GroupMessage {
    var groupId: String = ""
    var messages: [Message] = []
    var lastUpdated: Date = .init()
    var lastMessage: Message?
    var users: [Profile] = []
    
    init() {
        if let user = Repository<UserPrivate, UserPrivateObject>.shared.get() {
            self.users = [user.profile!]
        }
    }
}

extension GroupMessage {
    
}

extension GroupMessage: ObjectConvertable {
    typealias Object = GroupMessageObject
    
    func asObject() -> GroupMessageObject {
        let object = GroupMessageObject()
        object.groupId = self.groupId
        object.messages.append(objectsIn: self.messages.map { $0.asObject() })
        object.lastMessage = self.lastMessage?.asObject()
        object.users.append(objectsIn: self.users.map { $0.asObject() })
        object.lastUpdated = self.lastUpdated
        return object
    }
    
}

class GroupMessageObject: Object {
    @objc dynamic var groupId: String = ""
    @objc dynamic var lastUpdated: Date = .init()
    let messages: List<MessageObject> = List<MessageObject>()
    @objc dynamic var lastMessage: MessageObject?
    var users: List<ProfileObject> = List<ProfileObject>()
    
    override class func primaryKey() -> String? {
        return "groupId"
    }
}

extension GroupMessageObject: DomainConvertable {
    typealias Domain = GroupMessage
    
    func asDomain() -> GroupMessage {
        let domain = GroupMessage()
        domain.groupId = self.groupId
        domain.lastMessage = self.lastMessage?.asDomain()
        domain.messages.append(contentsOf: self.messages.map { $0.asDomain() })
        domain.users = self.users.map { $0.asDomain() }
        domain.lastUpdated = self.lastUpdated
        return domain
    }
    
    
}

extension GroupMessageObject: PrimaryValueProtocol {
    typealias K = String
    
    func primaryValue() -> String {
        return self.groupId
    }
}
