//
//  Profile.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON
import RealmSwift

public enum UserType: Int {
    case normal = 1
    case bookstop = 2
    case organization = 3
}

public class Profile {
    var id: Int = 0
    var username: String = ""
    var name: String = ""
    var address: String = ""
    var imageId: String = ""
    var coverImageId: String = ""
    var email: String = ""
    var about: String = ""
    var location: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var userTypeFlag: UserType = .normal
    
    init() {
        
    }
    
    init(id: Int,username:String, name: String, address: String, imageId: String, email: String, about: String, latitude: Double, longitude: Double, userTypeFlag: Int) {
        self.id = id
        self.username = username
        self.name = name
        self.address = address
        self.email = email
        self.about = about
        self.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.userTypeFlag = UserType(rawValue: userTypeFlag)!
        self.imageId = imageId
    }
    
    func parse(json: JSON) {
        print("JSON:\(json)")
        self.id = json["userId"].int ?? 0
        self.username = json["username"].string ?? ""
        self.name = json["name"].string ?? ""
        self.address = json["address"].string ?? ""
        self.imageId = json["imageId"].string ?? ""
        self.about = json["about"].string ?? ""
        let latitude = json["latitude"].double ?? 0.0
        let longitude = json["longitude"].double ?? 0.0
        self.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.userTypeFlag = UserType(rawValue: json["userTypeFlag"].int ?? 1) ?? .normal
        self.coverImageId = json["coverImageId"].string ?? ""
    }
    
    func update(new profile: Profile) {
        self.name = profile.name
        self.address = profile.address
        self.location = profile.location
        self.about = profile.about
        self.imageId = profile.imageId
        self.coverImageId = profile.coverImageId
        self.userTypeFlag = profile.userTypeFlag
    }
}

extension Profile: ObjectConvertable {
    typealias Object = ProfileObject
    
    func asObject() -> ProfileObject {
        let object = ProfileObject()
        object.id = self.id
        object.username = self.username
        object.name = self.name
        object.address = self.address
        object.email = self.email
        object.imageId = self.imageId
        object.coverImageId = self.coverImageId
        object.latitude = self.location.latitude
        object.longitude = self.location.longitude
        object.userTypeFlag = self.userTypeFlag.rawValue
        object.about = self.about
        return object
    }
    
    
}

extension Profile: CustomStringConvertible {
    public var description: String {
        return "Profile: { id = \(self.id),\n\tname = \(self.name),\n\temail = \(self.email),\n\taddress = \(self.address),\n\tlocation = \(self.location),\n\timageId = \(self.imageId),\n\tabout = \(self.about)\n}"
    }
}

class ProfileObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var username: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var address: String = ""
    @objc dynamic var imageId: String = ""
    @objc dynamic var coverImageId: String = ""
    @objc dynamic var email: String = ""
    @objc dynamic var about: String = ""
    @objc dynamic var latitude: Double = 0.0
    @objc dynamic var longitude: Double = 0.0
    @objc dynamic var userTypeFlag: Int = 0
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension ProfileObject: DomainConvertable {
    typealias Domain = Profile
    
    func asDomain() -> Profile {
        let domain = Profile()
        domain.id = self.id
        domain.username = self.username
        domain.name = self.name
        domain.address = self.address
        domain.imageId = self.imageId
        domain.about = self.about
        domain.coverImageId = self.coverImageId
        domain.location = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        domain.userTypeFlag = UserType(rawValue: self.userTypeFlag)!
        domain.email = self.email
        return domain
    }
    
}

extension ProfileObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        return self.id
    }
    
    
}


