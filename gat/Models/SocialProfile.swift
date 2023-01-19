//
//  SocailProfile.swift
//  gat
//
//  Created by Vũ Kiên on 20/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

enum SocialType: Int {
    case facebook = 1
    case google = 2
    case twitter = 3
    @available (iOS 13.0, *)
    case apple = 4
}

class SocialProfile {
    var id: String = ""
    var name: String = ""
    var email: String = ""
    var image: UIImage? = nil
    var type: SocialType = .facebook
    var statusLink = true
}

extension SocialProfile: ObjectConvertable {
    typealias Object = SocialProfileObject
    
    func asObject() -> SocialProfileObject {
        let object = SocialProfileObject()
        object.id = self.id
        object.name = self.name
        object.email = self.email
        //object.image = self.image?.imageData
        object.type = self.type.rawValue
        object.statusLink = self.statusLink
        return object
    }
}

class SocialProfileObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var email: String = ""
    @objc dynamic var image: Data?
    @objc dynamic var type: Int = 1
    @objc dynamic var statusLink = true
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension SocialProfileObject: DomainConvertable {
    typealias Domain = SocialProfile
    
    func asDomain() -> SocialProfile {
        let domain = SocialProfile()
        domain.id = self.id
        domain.name = self.name
        domain.email = self.email
        //domain.image = self.image
        domain.type = SocialType(rawValue: self.type) ?? .facebook
        domain.statusLink = self.statusLink
        return domain
    }
    
}

extension SocialProfileObject: PrimaryValueProtocol {
    typealias K = String

    func primaryValue() -> String {
        return self.id
    }
}
