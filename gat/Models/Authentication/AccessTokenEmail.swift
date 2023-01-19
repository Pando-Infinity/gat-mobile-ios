//
//  AccessToken.swift
//  gat
//
//  Created by Vũ Kiên on 23/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

@propertyWrapper
struct AccessToken {
    
    fileprivate let key: String
    
    var wrappedValue: String? {
        get {
            return UserDefaults.standard.string(forKey: self.key)
        }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: self.key)
            } else {
                UserDefaults.standard.removeObject(forKey: self.key)
            }
        }
    }
    
    init(key: String) {
        self.key = key
    }
}

internal class AccessTokenEmail {
    var id: Int = 0
    var token: String = ""
    var facebookToken: String = ""
    var googleToken: String = ""
    var twitterToken: String = ""
    
    init(id: Int, token: String) {
        self.id = id
        self.token = token
    }
    
    init() {
        
    }
    
    class var standard: Observable<AccessTokenEmail?>  {
        return Observable.just(Repository<AccessTokenEmail, AccessTokenObject>.shared.get())
    }
}

extension AccessTokenEmail: ObjectConvertable {
    typealias Object = AccessTokenObject
    
    func asObject() -> AccessTokenObject {
        let object = AccessTokenObject()
        object.id = self.id
        object.token = self.token
        object.facebookToken = self.facebookToken
        object.googleToken = self.googleToken
        object.twitterToken = self.twitterToken
        return object
    }
    
    
}



class AccessTokenObject: Object {
    
    @objc dynamic var id: Int = 0
    @objc dynamic var token: String = ""
    @objc dynamic var facebookToken: String = ""
    @objc dynamic var googleToken: String = ""
    @objc dynamic var twitterToken: String = ""
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension AccessTokenObject: DomainConvertable {
    typealias Domain = AccessTokenEmail
    
    func asDomain() -> AccessTokenEmail {
        let accessToken = AccessTokenEmail(id: self.id, token: self.token)
        accessToken.facebookToken = self.facebookToken
        accessToken.googleToken = self.googleToken
        accessToken.twitterToken = self.twitterToken
        return accessToken
    }
    
}

extension AccessTokenObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        return self.id
    }
    
    
}

