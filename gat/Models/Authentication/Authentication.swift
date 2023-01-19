//
//  Authentication.swift
//  gat
//
//  Created by jujien on 5/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation

struct Credentials {
    let email: String
    let password: String
    let confirmPassword: String
    
    init(email: String, password: String, confirmPassword: String = "") {
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
    }
}

struct CredentialSocial {
    let profile: SocialProfile
    let priority: Priority
}

extension CredentialSocial {
    enum Priority {
        case signIn
        case signUp
    }
}

protocol Authentication {
    var principal: Any { get }
    var credential: Any { get }
    var name: String { get }
}

struct DefaultAuthentication: Authentication {
    var principal: Any
    
    var credential: Any
    
    var name: String
}

extension DefaultAuthentication {
    static let USERNAME_PASSWORD = "username_password"
    
    static let SOCIAL = "social"
    
    static let TOKEN = "token"
    
    static let PROFILE = "profile"
}
