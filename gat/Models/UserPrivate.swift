//
//  UserPrivate.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON
import RealmSwift

enum UserLoginStatus: Int {
    case email = 0
    case facebook = 1
    case google = 2
    case twitter = 3
}

class UserPrivate: UserTypeProtocol {
    var id: Int = 0
    var profile: Profile?
    var passwordFlag: Bool = false
    var socials: [SocialProfile] = []
    var interestCategory: [Category] = []
    var instanceCount: Int = 0
    var reviewCount: Int = 0
    var articleCount:Int = 0
    var requestCount: Int = 0
    var bookstops: [Bookstop] = []
    var statusLogin: UserLoginStatus = .email
    
    init() {
        self.profile = Profile()
    }
    
    func parse(json: JSON) {
        self.id = json["userId"].int ?? 0
        self.profile = Profile()
        self.profile?.parse(json: json)
        if let faceBookName = json["faceBookName"].string, !faceBookName.isEmpty {
            let facebook = SocialProfile()
            facebook.id = json["facebookId"].string ?? ""
            facebook.name = faceBookName
            facebook.type = .facebook
            socials.append(facebook)
        }
        if let googleName = json["googleName"].string, !googleName.isEmpty {
            let google = SocialProfile()
            google.name = googleName
            google.id = json["googleId"].string ?? ""
            google.type = .google
            self.socials.append(google)
        }
        if let twitterName = json["twitterName"].string, !twitterName.isEmpty {
            let twitter = SocialProfile()
            twitter.name = twitterName
            twitter.type = .twitter
            twitter.id = json["twitterId"].string ?? ""
            self.socials.append(twitter)
        }
        self.interestCategory = json["interestCategories"].array?.compactMap({ (json) -> Category? in
            guard let categoryId = json["categoryId"].int else {
                return nil
            }
            return Category.all.filter { $0.id == categoryId }.first
        }) ?? []
        self.bookstops = json["bookstops"].array?.map({ (json) -> Bookstop in
            let bookstop = Bookstop()
            bookstop.profile = Profile()
            bookstop.id = json["bookstopId"].int ?? 0
            bookstop.profile?.id = json["bookstopId"].int ?? 0
            bookstop.profile?.name = json["name"].string ?? ""
            bookstop.profile?.imageId = json["imageId"].string ?? ""
            bookstop.profile?.address = json["address"].string ?? ""
            bookstop.profile?.coverImageId = json["coverImageId"].string ?? ""
            let kind = BookstopKindOrganization()
            kind.status = UserBookstopStatus(rawValue: json["status"].int ?? -1)
            bookstop.kind = kind
            return bookstop
        }) ?? []
        self.instanceCount = json["instanceCount"].int ?? 0
        self.reviewCount = json["reviewCount"].int ?? 0
        self.requestCount = json["requestCount"].int ?? 0
        self.articleCount = json["articleRelation"]["articleCount"].int ?? 0
        if json["passwordFlag"].int == 1 {
            self.passwordFlag = true
        } else {
            self.passwordFlag = false 
        }
    }
    
    func update(new userPrivate: UserPrivate) {
        self.bookstops = userPrivate.bookstops
        self.interestCategory = userPrivate.interestCategory
        self.reviewCount = userPrivate.reviewCount
        self.instanceCount = userPrivate.instanceCount
        self.articleCount = userPrivate.articleCount
        self.profile?.update(new: userPrivate.profile!)
        userPrivate.passwordFlag = self.passwordFlag
        zip(self.socials, userPrivate.socials).forEach { (old, new) in
            old.name = new.name
        }
    }
}

extension UserPrivate: CustomStringConvertible {
    var description: String {
        return "UserPrivate = {\n\tid = \(self.id),\n\tprofile = \(String(describing: self.profile)),\n\tinterestCategory = \(self.interestCategory)\n}"
    }
    
    
}

extension UserPrivate: ObjectConvertable {
    typealias Object = UserPrivateObject
    
    func asObject() -> UserPrivateObject {
        let object = UserPrivateObject()
        object.id = self.id
        object.socials.append(objectsIn: self.socials.map { $0.asObject() })
        object.profile = self.profile?.asObject()
        object.profile?.email = UserDefaults.standard.string(forKey: "email") ?? ""
        object.interestCategory.append(objectsIn: self.interestCategory.map { $0.asObject() })
        object.bookstops.append(objectsIn: self.bookstops.map { $0.asObject() })
        object.instanceCount = self.instanceCount
        object.reviewCount = self.reviewCount
        object.requestCount = self.requestCount
        object.articleCount = self.articleCount
        object.statusLogin = self.statusLogin.rawValue
        object.passwordFlag = self.passwordFlag
        return object
    }
}

class UserPrivateObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var profile: ProfileObject?
    @objc dynamic var passwordFlag: Bool = false
    let socials = List<SocialProfileObject>()
    let interestCategory = List<CategoryObject>()
    let bookstops = List<BookstopObject>()
    @objc dynamic var instanceCount: Int = 0
    @objc dynamic var reviewCount: Int = 0
    @objc dynamic var requestCount: Int = 0
    @objc dynamic var articleCount: Int = 0
    @objc dynamic var statusLogin: Int = 0
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension UserPrivateObject: DomainConvertable {
    typealias Domain = UserPrivate
    
    func asDomain() -> UserPrivate {
        let domain = UserPrivate()
        domain.id = self.id
        domain.socials = self.socials.map { $0.asDomain() }
        domain.profile = self.profile?.asDomain()
        domain.profile?.email = UserDefaults.standard.string(forKey: "email") ?? ""
        domain.passwordFlag = self.passwordFlag
        domain.interestCategory.append(contentsOf: self.interestCategory.map { $0.asDomain() })
        domain.bookstops.append(contentsOf: self.bookstops.map { $0.asDomain() })
        domain.instanceCount = self.instanceCount
        domain.reviewCount = self.reviewCount
        domain.requestCount = self.requestCount
        domain.articleCount = self.articleCount
        domain.statusLogin = UserLoginStatus(rawValue: self.statusLogin) ?? .email
        return domain
    }
}

extension UserPrivateObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        return self.id
    }
    
    
}

