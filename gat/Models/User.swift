//
//  User.swift
//  gat
//
//  Created by HungTran on 2/23/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import SwiftyJSON

/**Model dùng để lưu tất cả thông tin người dùng*/
class User: Object {
    
    @objc dynamic var id: Int = -1
    @objc dynamic var name: String = ""
    @objc dynamic var email: String = ""
    @objc dynamic var userTypeFlag: Int = -1 // 1: Normal, 2: BookStop
    @objc dynamic var passwordFlag: Int = -1
    @objc dynamic var imageId: String = "" // Mã ảnh đại diện của người dùng
    @objc dynamic var coverImageId: String = ""
    
    @objc dynamic var faceBookId: String = ""
    @objc dynamic var faceBookName: String = ""
    @objc dynamic var googleId: String = ""
    @objc dynamic var googleName: String = ""
    @objc dynamic var twitterId: String = ""
    @objc dynamic var twitterName: String = ""
    
    @objc dynamic var about: String = ""
    
    @objc dynamic var fbLink: String = ""
    @objc dynamic var insLink: String = ""
    @objc dynamic var twLink: String = ""
    
    @objc dynamic var address = ""
    @objc dynamic var latitude = 0.0
    @objc dynamic var longtitude = 0.0
    @objc dynamic var distance = 0.0
    
    var activeFlag: Bool = false
    
    let interestCategory = List<BookCategory>()
    let usuallyLocations = List<Address>()
    let bookstops = List<BookstopRealm>()
    
    @objc dynamic var readCount = 0
    @objc dynamic var sharingCount = 0
    @objc dynamic var requestCount: Int = 0
    @objc dynamic var reviewCount: Int = 0
    
    static let adminId = 0
    
    /**Cài đặt khoá chính cho bảng*/
    override static func primaryKey() -> String {
        return "id"
    }
    
    static func create(userId: Int, name: String, imageId: String, address: String, distance: Double) -> User {
        let user = User()
        user.id = userId
        user.name = name
        user.imageId = imageId
        user.address = address
        user.distance = distance
        return user
    }
    
    static func create(id: Int, name: String, imageId: String, address: String, userTypeFlag: Int) -> User {
        let user = User()
        user.id = id
        user.name = name
        user.imageId = imageId
        user.address = address
        user.userTypeFlag = userTypeFlag
        return user
    }
    
    static func create(id: Int, name: String, imageId: String, address: String, latitude: Double, longtitude: Double, distance: Double, readCount: Int, sharingCount: Int) -> User {
        let user = User()
        user.id = id
        user.name = name
        user.imageId = imageId
        user.address = address
        user.latitude = latitude
        user.longtitude = longtitude
        user.distance = distance
        user.readCount = readCount
        user.sharingCount = sharingCount
        return user
    }
    
    //MARK: - Parse json tra ve array Friend
    ///khi json tra ve list ban be gan nhat
    static func nearByParse(json: JSON) -> [User] {
        let data = json["data"]
        guard let resultInfo = data["resultInfo"].array else {
            return []
        }
        
        let users = resultInfo.flatMap { (json) -> User? in
            guard let id = json["userId"].int, let name = json["name"].string, let imageId = json["imageId"].string, let latitude = json["latitude"].double, let longitude = json["longitude"].double, let distance = json["distance"].double, let readCount = json["readCount"].int, let sharingCount = json["sharingCount"].int, let userTypeFlag = json["userTypeFlag"].int, let activeFlag = json["activeFlag"].bool, let reviewCount = json["reviewCount"].int else {
                return nil
            }
             let address = json["address"].string ?? ""
            let user = User.create(id: id, name: name, imageId: imageId, address: address, latitude: latitude, longtitude: longitude, distance: distance, readCount: readCount, sharingCount: sharingCount)
            user.userTypeFlag = userTypeFlag
            user.activeFlag = activeFlag
            user.reviewCount = reviewCount
            return user
        }
        
        return users
    }
    
    ///khi json tra ve ket qua search
    static func searchParse(json: JSON) -> [User] {
        var users = [User]()
        let data = json["data"]
        guard let resultInfo = data["resultInfo"].array else {
            return users
        }
        users = resultInfo.flatMap { (json) -> User? in
            guard let id = json["userId"].int, let name = json["name"].string, let imageId = json["imageId"].string, let address = json["address"].string, let userTypeFlag = json["userTypeFlag"].int, let sharingCount = json["sharingCount"].int, let distance = json["distance"].double else {
                return nil
            }
            let user = User.create(id: id, name: name, imageId: imageId, address: address, userTypeFlag: userTypeFlag)
            user.sharingCount = sharingCount
            user.distance = distance
            return user
        }
        return users
    }
    
    /**Dọn dẹp dữ liệu của User
     + BookInstant
     + ReadingBookInstant
     + BorrowingBookRequest*/
    static func resetData() {
        try? Realm().safeWrite {
            try? Realm().delete(Realm().objects(BookInstant.self))
            try? Realm().delete(Realm().objects(ReadingBookInstant.self))
            try? Realm().delete(Realm().objects(BorrowingBookRequest.self))
        }
    }
    
    /**Trả về đối tượng User từ JSON 
     (nếu đối tượng đã tồn tại trong DB thì chỉ sửa đối tượng sau đó trả về User*/
    static func parseFrom(json: JSON?) -> User? {
//        print("User.parseFrom: ", json)
        guard let json = json else { return nil }
        guard let id = json["userId"].int else {
            return nil
        }
        if let user = try! Realm().object(ofType: User.self, forPrimaryKey: id) {
            try! Realm().safeWrite {
                if json["name"].exists(), let name = json["name"].string {
                    user.name = name
                }
                if json["email"].exists(), let email = json["email"].string {
                    user.email = email
                }
                if json["imageId"].exists(), let imageId = json["imageId"].string {
                    user.imageId = imageId
                }
                
                user.coverImageId = json["coverImageId"].string ?? ""
                user.address = json["address"].string ?? ""
                
                if json["userTypeFlag"].exists(), let userTypeFlag = json["userTypeFlag"].int {
                    user.userTypeFlag = userTypeFlag
                }
                if json["passwordFlag"].exists(), let passwordFlag = json["passwordFlag"].int {
                    user.passwordFlag = passwordFlag
                }
                
                if json["faceBookId"].exists() {
                    user.faceBookId = json["faceBookId"].string ?? ""
                }
                
                if json["faceBookName"].exists() {
                    user.faceBookName = json["faceBookName"].string ?? ""
                }
                if json["googleId"].exists() {
                    user.googleId = json["googleId"].string ?? ""
                }
                
                if json["googleName"].exists() {
                    user.googleName = json["googleName"].string ?? ""
                }
                
                if json["twitterId"].exists() {
                    user.twitterId = json["twitterId"].string ?? ""
                }
                
                if json["twitterName"].exists() {
                    user.twitterName = json["twitterName"].string ?? ""
                }
                
                user.fbLink = json["fbLink"].string ?? ""
                user.insLink = json["insLink"].string ?? ""
                user.twLink = json["twLink"].string ?? ""
                
                user.about = json["about"].string ?? ""
                
                if json["address"].exists(), let address = json["address"].string {
                    user.address = address
                }
                if json["latitude"].exists(), let latitude = json["latitude"].double {
                    user.latitude = latitude
                }
                if json["longtitude"].exists(), let longtitude = json["longtitude"].double {
                    user.latitude = longtitude
                }
                if json["distance"].exists(), let distance = json["distance"].double {
                    user.distance = distance
                }
                
                if json["readCount"].exists(), let readCount = json["readCount"].int {
                    user.readCount = readCount
                }
                if json["instanceCount"].exists(), let sharingCount = json["instanceCount"].int {
                    user.sharingCount = sharingCount
                }
                if json["requestCount"].exists(), let requestCount = json["requestCount"].int {
                    user.requestCount = requestCount
                }
                if let reviewCount = json["reviewCount"].int {
                    user.reviewCount = reviewCount
                }
                if json["interestCategory"].exists(), let interestCategories = json["interestCategory"].array {
                    user.interestCategory.removeAll()
                    for tmpCategory in interestCategories {
                        if let category = BookCategory.parseFrom(json: tmpCategory) {
                            user.interestCategory.append(category)
                        }
                    }
                }
                if json["usuallyLocation"].exists(), let usuallyLocations = json["usuallyLocation"].array {
                    user.usuallyLocations.removeAll()
                    for location in usuallyLocations {
                        if let address = Address.parseFrom(json: location) {
                            user.usuallyLocations.append(address)
                        }
                    }
                }
                user.bookstops.removeAll()
                user.bookstops.append(objectsIn: BookstopRealm.parse(json: json["bookstops"]))
            }
            return user
        } else {
            let user = User()
            
            user.id = id
            user.name = json["name"].string ?? ""
            user.email = json["email"].string ?? ""
            user.imageId = json["imageId"].string ?? ""
            user.coverImageId = json["coverImageId"].string ?? ""
            user.userTypeFlag = json["userTypeFlag"].int ?? -1
            user.passwordFlag = json["passwordFlag"].int ?? -1

            user.faceBookId = json["faceBookId"].string ?? ""
            user.faceBookName = json["faceBookName"].string ?? ""
            user.googleId = json["googleId"].string ?? ""
            user.googleName = json["googleName"].string ?? ""
            user.twitterId = json["twitterId"].string ?? ""
            user.twitterName = json["twitterName"].string ?? ""
            
            user.fbLink = json["fbLink"].string ?? ""
            user.insLink = json["insLink"].string ?? ""
            user.twLink = json["twLink"].string ?? ""
            
            user.about = json["about"].string ?? ""
            
            user.address = json["address"].string ?? ""
            user.latitude = json["latitude"].double ?? 0.0
            user.longtitude = json["longtitude"].double ?? 0.0
            user.distance = json["distance"].double ?? 0.0
            user.readCount = json["readCount"].int ?? 0
            user.sharingCount = json["instanceCount"].int ?? 0
            user.requestCount = json["requestCount"].int ?? 0
            user.reviewCount = json["reviewCount"].int ?? 0

            
            if json["interestCategory"].exists(), let interestCategories = json["interestCategory"].array {
                for tmpCategory in interestCategories {
                    if let category = BookCategory.parseFrom(json: tmpCategory) {
                        user.interestCategory.append(category)
                    }
                }
            }
            
            if json["usuallyLocation"].exists(), let usuallyLocations = json["usuallyLocation"].array {
                for location in usuallyLocations {
                    if let address = Address.parseFrom(json: location) {
                        user.usuallyLocations.append(address)
                    }
                }
            }
            user.bookstops.removeAll()
            user.bookstops.append(objectsIn: BookstopRealm.parse(json: json["bookstops"]))
            return user
        }
    }
    
    //get info
    static func getInfo(userId: Int, json: JSON) -> User? {
        let data = json["data"]
        let resultInfo = data["resultInfo"]
        guard let name = resultInfo["name"].string, let imageId = resultInfo["imageId"].string else {
            return nil
        }
        let user = User()
        user.id = userId
        user.name = name
        user.imageId = imageId
        return user
    }
    
    // Get user by Id
    static func getUserById(_ userId: Int) -> User? {
        return try! Realm().object(ofType: User.self, forPrimaryKey: userId)
    }
}
