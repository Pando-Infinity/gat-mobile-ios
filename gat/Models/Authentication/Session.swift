//
//  Session.swift
//  gat
//
//  Created by jujien on 5/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

class Session {
    
    static let shared = Session()
    
    @AccessToken(key: "access_token")
    var accessToken: String?
    
    var user: UserPrivate? {
        get {
            Repository<UserPrivate, UserPrivateObject>.shared.get()
        }
        
        set {
            if let user = newValue {
                Repository<UserPrivate, UserPrivateObject>.shared.save(object: user).subscribe().disposed(by: self.disposeBag)
            } else {
                Repository<UserPrivate, UserPrivateObject>.shared.removeAll().subscribe().disposed(by: self.disposeBag)
            }
        }
    }
    
    var isAuthenticated: Bool { self.user != nil && self.accessToken != nil }
    
    fileprivate let disposeBag = DisposeBag()
    
    fileprivate init() { }
    
    func remove() {
        self.accessToken = nil
        self.user = nil
    }
    
}
