//
//  Instance.swift
//  gat
//
//  Created by Vũ Kiên on 16/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON
import RealmSwift

enum SharingStatus: Int {
    typealias RawValue = Int
    
    case notSharing = 0
    case sharing = 1
    case borrowing = 2
    case lost = -1
    case readInPlace = 4
    case selfManagerAndAvailable = 5
    case selfManagerAndNotAvailable = 6
    case requestAndAvailable = 7
    case requestAndNotAvailble = 8
}

protocol UserTypeProtocol: class {
    var profile: Profile? { get set }
}

class Instance {
    var id: Int = 0
    var owner: UserTypeProtocol?
    var book: BookInfo
    var borrower: Profile?
    var addDate: Date
    var startShareDate: Date
    var sharingStatus: SharingStatus?
    var bookstopMember: Bool = false
    var request: BookRequest?
    
    /*(Đánh dấu là xoá để trường hợp không xoá thành công trên server
    thì vẫn xoá trên client để lần sau có mạng vẫn xoá lại được)
     */
    var deleteFlag: Bool = false
    
    init() {
        self.book = BookInfo()
        self.addDate = Date()
        self.startShareDate = Date()
    }
    
    func parse(json: JSON) {
        self.id = json["instanceInfo"]["instanceId"].int ?? 0
        if let userTypeFlag = json["owner"]["userTypeFlag"].int, userTypeFlag == 3 {
            let bookstop = Bookstop()
            bookstop.id = json["owner"]["userId"].int ?? 0
            bookstop.profile?.id = json["owner"]["userId"].int ?? 0
            bookstop.profile?.name = json["owner"]["name"].string ?? ""
            bookstop.profile?.imageId = json["owner"]["imageId"].string ?? ""
            bookstop.profile?.address = json["owner"]["address"].string ?? ""
            bookstop.profile?.userTypeFlag = UserType(rawValue: json["owner"]["userTypeFlag"].int ?? 1) ?? .normal
            bookstop.profile?.coverImageId = json["owner"]["coverImageId"].string ?? ""
            bookstop.profile?.about = json["owner"]["about"].string ?? ""
            bookstop.memberType = MemberType(rawValue: json["owner"]["memberType"].int ?? 0) ?? .open
            let kind = BookstopKindOrganization()
            kind.totalMemeber = json["owner"]["totalMember"].int ?? 0
            kind.totalEdition = json["owner"]["totalEdition"].int ?? 0
            bookstop.kind = kind
            self.owner = bookstop
        }
        self.book.editionId = json["edition"]["editionId"].int ?? 0
        self.book.title = json["edition"]["title"].string ?? ""
        self.book.author = json["edition"]["author"].string ?? ""
        self.book.rateAvg = json["edition"]["rateAvg"].double ?? 0.0
        self.book.imageId = json["edition"]["imageId"].string ?? ""
        self.startShareDate = .init(timeIntervalSince1970: (json["instanceInfo"]["startShareDate"].double ?? 0.0) / 1000.0)
        self.addDate = .init(timeIntervalSince1970: (json["instanceInfo"]["userAddDate"].double ?? 0.0) / 1000.0)
        self.sharingStatus = SharingStatus(rawValue: json["instanceInfo"]["sharingStatus"].int ?? 1)
        if let recordId = json["instanceInfo"]["recordId"].int {
            self.request = BookRequest()
            self.request?.recordId = recordId
            self.request?.recordStatus = RecordStatus(rawValue: json["instanceInfo"]["recordstatus"].int ?? -1)
            self.request?.borrowTime = .init(timeIntervalSince1970: (json["instanceInfo"]["borrowTime"].double ?? 0.0) / 1000.0)
            self.request?.completeTime = .init(timeIntervalSince1970: (json["instanceInfo"]["borrowingDuration"].double ?? 0.0) / 1000.0)
        }
        if let userId = json["borrower"]["userId"].int {
            self.borrower = Profile()
            self.borrower?.id = userId
            self.borrower?.name = json["borrower"]["name"].string ?? ""
            self.borrower?.imageId = json["borrower"]["imageId"].string ?? ""
            self.borrower?.address = json["borrower"]["address"].string ?? ""
            self.borrower?.userTypeFlag = UserType(rawValue: json["borrower"]["userTypeFlag"].int ?? 1) ?? .normal
            self.borrower?.about = json["borrower"]["about"].string ?? ""
        }
        self.bookstopMember = json["instanceInfo"]["bookstopMember"].bool ?? false
    }
}

extension Instance: ObjectConvertable {
    typealias Object = InstanceObject
    
    func asObject() -> InstanceObject {
        let object = InstanceObject()
        object.id = self.id
        object.book = self.book.asObject()
        object.owner = self.owner?.profile?.asObject()
        object.borrower = self.borrower?.asObject()
        object.sharingStatus = self.sharingStatus?.rawValue ?? 1
        object.deleteFlag = self.deleteFlag
        object.request = self.request?.asObject()
        return object
    }
    
    
}

class InstanceObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var book: BookInfoObject?
    @objc dynamic var owner: ProfileObject?
    @objc dynamic var borrower: ProfileObject?
    @objc dynamic var sharingStatus: Int = -1
    @objc dynamic var deleteFlag: Bool = false
    @objc dynamic var request: BookRequestObject?
    
    override static func primaryKey() -> String {
        return "id"
    }
    
}

extension InstanceObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        return self.id
    }
    
    
}

extension InstanceObject: DomainConvertable {
    typealias Domain = Instance
    
    func asDomain() -> Instance {
        let domain = Instance()
        domain.id = self.id
        domain.book = self.book?.asDomain() ?? BookInfo()
        if self.owner?.asDomain().userTypeFlag == .normal {
            let userPrivate = UserPrivate()
            userPrivate.id = self.owner?.id ?? 0
            userPrivate.profile = self.owner?.asDomain()
            domain.owner = userPrivate
        } else if self.owner?.asDomain().userTypeFlag == .organization {
            let bookstop = Bookstop()
            bookstop.profile = self.owner?.asDomain()
            bookstop.id = self.owner?.id ?? 0
            domain.owner = bookstop
        }
        domain.sharingStatus = SharingStatus(rawValue: self.sharingStatus)
        domain.deleteFlag = self.deleteFlag
        domain.borrower = self.borrower?.asDomain()
        domain.request = self.request?.asDomain()
        return domain
    }
    
}
