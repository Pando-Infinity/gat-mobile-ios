//
//  UserNotification.swift
//  gat
//
//  Created by Vũ Kiên on 30/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON
import RealmSwift

class UserNotification {
    var notificationId: Int = -1
    var notificationType: Int = -1
    var destId: Int = -1
    var user: Profile?
    var targetId: Int = -1
    var targetName: String = ""
    var referId: Int = -1
    var referName: String = ""
    var pullFlag: Bool = false
    var beginTime: Date = Date()
    var relationCount:Int = 0
    
    static func parseNotify(json: JSON) -> Int {
        let data = json["data"]
        return data["notifyTotal"].int ?? 0
    }
}

extension UserNotification: ObjectConvertable {
    typealias Object = UserNotificationObject
    
    func asObject() -> UserNotificationObject {
        let object = UserNotificationObject()
        object.notificationId = self.notificationId
        object.notificationType = self.notificationType
        object.destId = self.destId
        object.user = self.user?.asObject()
        object.targetId = self.targetId
        object.targetName = self.targetName
        object.referId = self.referId
        object.referName = self.referName
        object.pullFlag = self.pullFlag
        object.beginTime = self.beginTime
        object.relationCount = self.relationCount
        return object
    }
    
    
}

class UserNotificationObject: Object {
    @objc dynamic var notificationId: Int = -1
    @objc dynamic var notificationType: Int = -1
    @objc dynamic var destId: Int = -1
    @objc dynamic var user: ProfileObject?
    @objc dynamic var targetId: Int = -1
    @objc dynamic var targetName: String = ""
    @objc dynamic var referId: Int = -1
    @objc dynamic var referName: String = ""
    @objc dynamic var pullFlag: Bool = false
    @objc dynamic var beginTime: Date = Date()
    @objc dynamic var relationCount: Int = 0
    
    override class func primaryKey() -> String? {
        return "notificationId"
    }
}

extension UserNotificationObject: DomainConvertable {
    typealias Domain = UserNotification
    
    func asDomain() -> UserNotification {
        let domain = UserNotification()
        domain.notificationId = self.notificationId
        domain.notificationType = self.notificationType
        domain.destId = self.destId
        domain.user = self.user?.asDomain()
        domain.targetId = self.targetId
        domain.targetName = self.targetName
        domain.referId =  self.referId
        domain.referName = self.referName
        domain.pullFlag = self.pullFlag
        domain.beginTime = self.beginTime
        domain.relationCount = self.relationCount
        return domain
    }
    
}
