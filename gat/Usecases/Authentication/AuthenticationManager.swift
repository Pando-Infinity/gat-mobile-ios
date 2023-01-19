//
//  AuthenticationManager.swift
//  gat
//
//  Created by jujien on 5/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

protocol AuthenticationManager {
    
    func authenticated(authentication: Authentication) -> Observable<Authentication>
}


// MARK: - Sign In
struct SocialAuthenticationManager: AuthenticationManager {
    func authenticated(authentication: Authentication) -> Observable<Authentication> {
        guard let profile = authentication.principal as? SocialProfile else { return .empty() }
        return UserNetworkService.shared
            .login(social: profile, uuid: UIDevice.current.identifierForVendor?.uuidString ?? "")
            .map { DefaultAuthentication(principal: $0.token, credential: "", name: DefaultAuthentication.TOKEN) }
    }
}

struct UsernamePasswordAuthenticationManager: AuthenticationManager {
    
    func authenticated(authentication: Authentication) -> Observable<Authentication> {
        guard let email = authentication.principal as? String, let password = authentication.credential as? String, authentication.name == DefaultAuthentication.USERNAME_PASSWORD else { return .empty() }
        return UserNetworkService.shared
            .login(email: email, password: password, uuid: UIDevice.current.identifierForVendor?.uuidString ?? "")
            .map { DefaultAuthentication(principal: $0.token, credential: "", name: DefaultAuthentication.TOKEN) }
    }
}

// MARK: - Sign Up

struct UsernamePasswordSignUp: AuthenticationManager {
    func authenticated(authentication: Authentication) -> Observable<Authentication> {
        guard let email = authentication.principal as? String, let password = authentication.credential as? String, authentication.name == DefaultAuthentication.USERNAME_PASSWORD else { return .empty() }
        return UserNetworkService.shared
            .register(email: email, password: password, uuid: UIDevice.current.identifierForVendor?.uuidString ?? "")
            .map { DefaultAuthentication(principal: $0.token, credential: "", name: DefaultAuthentication.TOKEN) }
    }
}

struct SocialSignUp: AuthenticationManager {
    func authenticated(authentication: Authentication) -> Observable<Authentication> {
        guard let profile = authentication.principal as? SocialProfile, let password = authentication.credential as? String else { return .empty() }
        return UserNetworkService.shared
            .register(social: profile, password: password, uuid: UIDevice.current.identifierForVendor?.uuidString ?? "")
            .map { DefaultAuthentication(principal: $0.token, credential: "", name: DefaultAuthentication.TOKEN) }
    }
}

// MARK: - Common
struct TokenAuthenticationManager: AuthenticationManager {
    
    var manager: AuthenticationManager
    
    func authenticated(authentication: Authentication) -> Observable<Authentication> {
        guard authentication.name != DefaultAuthentication.TOKEN, authentication.name != DefaultAuthentication.PROFILE else { return .empty() }
        return self.manager.authenticated(authentication: authentication)
            .filter { $0.name == DefaultAuthentication.TOKEN }
    }
}

struct ProfileAuthenticationManager: AuthenticationManager {
    func authenticated(authentication: Authentication) -> Observable<Authentication> {
        guard let token = authentication.principal as? String, authentication.name == DefaultAuthentication.TOKEN else { return .empty() }
        return UserNetworkService.shared.privateInfo(with: token)
            .map { DefaultAuthentication(principal: $0, credential: token, name: DefaultAuthentication.PROFILE) }
    }
}

struct DecoratorAuthenticationManager: AuthenticationManager {
    var tokenManager: AuthenticationManager
    var profileManager: AuthenticationManager
    
    func authenticated(authentication: Authentication) -> Observable<Authentication> {
        return self.tokenManager.authenticated(authentication: authentication)
            .flatMap(self.profileManager.authenticated(authentication:))
    }
}

struct SocialPriorityAuthenticationManager: AuthenticationManager {
    
    let signIn: AuthenticationManager
    
    let signUp: AuthenticationManager
        
    func authenticated(authentication: Authentication) -> Observable<Authentication> {
        guard let credentials = authentication.principal as? CredentialSocial else { return .empty() }
        switch credentials.priority {
        case .signIn: return self.signIn.authenticated(authentication: DefaultAuthentication(principal: credentials.profile, credential: authentication.credential, name: authentication.name))
            .catchError { (error) -> Observable<Authentication> in
                self.handle(error: error, authentication: authentication)
            }
        case .signUp: return self.signUp.authenticated(authentication:  DefaultAuthentication(principal: credentials.profile, credential: authentication.credential, name: authentication.name))
            .catchError { (error) -> Observable<Authentication> in
                self.handle(error: error, authentication: authentication)
            }
        }
    }
    
    func handle(error: Error, authentication: Authentication) -> Observable<Authentication> {
        guard let e = error as? ServiceError, let credentials = authentication.principal as? CredentialSocial, e.code != -1 else { return .error(error) }
        switch credentials.priority {
        case .signUp: return self.signIn.authenticated(authentication: DefaultAuthentication(principal: credentials.profile, credential: authentication.credential, name: authentication.name))
        case .signIn: return self.signUp.authenticated(authentication: DefaultAuthentication(principal: credentials.profile, credential: authentication.credential, name: authentication.name))
        }
    }
}

struct AppleAuthenticationManager: AuthenticationManager {
    func authenticated(authentication: Authentication) -> Observable<Authentication> {
        guard let profile = authentication.principal as? SocialProfile, authentication.name == DefaultAuthentication.SOCIAL else { return .empty() }
        return UserNetworkService.shared.loginApple(social: profile, uuid: UIDevice.current.identifierForVendor?.uuidString ?? "")
            .map { DefaultAuthentication(principal: $0.token, credential: "", name: DefaultAuthentication.TOKEN) }
    }
    
    
}

