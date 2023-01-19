//
//  Bookstop.swift
//  gat
//
//  Created by Vũ Kiên on 04/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON
import RealmSwift

enum UserBookstopStatus: Int {
    case waitting = 0
    case accepted = 1
}

enum BookstopType {
    case `public`
    case organization
}

enum MemberType: Int {
    case notAvailable = -1
    case open = 0
    case closed = 1
}

public protocol BookstopKind: class {
    
}

class BookstopKindOrganization {
    var totalMemeber: Int = 0
    var totalEdition: Int = 0
    var status: UserBookstopStatus?
}

extension BookstopKindOrganization: BookstopKind {
    
}

class BookstopKindPulic {
    var sharingBook: Int = 0
}

extension BookstopKindPulic: BookstopKind {
    
}

public class Bookstop: UserTypeProtocol {
    var id: Int = 0
    var profile: Profile?
    var images: [BookstopImage]
    var kind: BookstopKind?
    var activeFlag: Bool = false
    var distance: Double = 0.0
    var fbLink: String?
    var insLink: String?
    var twLink: String?
    var memberType: MemberType = .open
    
    init() {
        self.profile = Profile()
        self.images = []
    }
    
    func parse(json: JSON) {
        self.id = json["id"].int ?? 0
        self.profile?.parse(json: json)
        self.images = BookstopImage.parse(json: json)
        self.activeFlag = json["activeFlag"].bool ?? false
        self.distance = json["distance"].double ?? 0.0
        (self.kind as? BookstopKindOrganization)?.status = UserBookstopStatus(rawValue: json["status"].int ?? -1)
    }
}

extension Bookstop: ObjectConvertable {
    typealias Object = BookstopObject
    
    func asObject() -> BookstopObject {
        let object = BookstopObject()
        object.id = self.id
        object.profile = self.profile?.asObject()
        object.images.append(objectsIn: self.images.map { $0.asObject() })
        object.status = (self.kind as? BookstopKindOrganization)?.status?.rawValue ?? -1
        return object
    }
    
}


class BookstopObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var profile: ProfileObject?
    let images = List<BookstopImageObject>()
    @objc dynamic var status: Int = -1
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension BookstopObject: DomainConvertable {
    typealias Domain = Bookstop
    
    func asDomain() -> Bookstop {
        let domain = Bookstop()
        domain.id = self.id
        domain.profile = self.profile?.asDomain()
        domain.images = self.images.map { $0.asDomain() }
        let kind = BookstopKindOrganization()
        kind.status = UserBookstopStatus(rawValue: self.status)
        domain.kind = kind
        return domain
    }
    
}

extension BookstopObject: PrimaryValueProtocol {
    typealias K = Int
    func primaryValue() -> Int {
        return self.id
    }
    
    
}
