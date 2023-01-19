//
//  AuthenticationUsecase.swift
//  gat
//
//  Created by jujien on 5/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import AuthenticationServices

protocol AuthenticationUseCase {
    func signIn(email: String, password: String) -> Observable<()>
    
    func signIn(social type: SocialType) -> Observable<()>
    
    func signUp(email: String, password: String) -> Observable<()>
    
    func signUp(social type: SocialType) -> Observable<()>
    
    @available(iOS 13.0, *)
    func signIn(credentials: AppleCredential) -> Observable<()>
}

struct DefaultAuthenticationUseCase: AuthenticationUseCase {
    fileprivate let authenticationManager: AuthenticationManager
    fileprivate let signUpManager: AuthenticationManager
    fileprivate let socialAuthenticationManager: AuthenticationManager
    fileprivate let googleService: GoogleService = .init()
    fileprivate let appleAuthenticationManager:AuthenticationManager
    fileprivate let disposeBag = DisposeBag()
    
    init(authenticationManager: AuthenticationManager, signUpManager: AuthenticationManager, socialAuthenticationManager: AuthenticationManager,appleAuthenticationManager:AuthenticationManager) {
        self.authenticationManager = authenticationManager
        self.signUpManager = signUpManager
        self.socialAuthenticationManager = socialAuthenticationManager
        self.appleAuthenticationManager = appleAuthenticationManager
    }
    
    init() {
        self.authenticationManager = DecoratorAuthenticationManager(tokenManager: TokenAuthenticationManager(manager: UsernamePasswordAuthenticationManager()), profileManager: ProfileAuthenticationManager())
        
        self.signUpManager = DecoratorAuthenticationManager(tokenManager: TokenAuthenticationManager(manager: UsernamePasswordSignUp()), profileManager: ProfileAuthenticationManager())
        
        self.socialAuthenticationManager = DecoratorAuthenticationManager(tokenManager: TokenAuthenticationManager(manager:
            SocialPriorityAuthenticationManager(signIn: SocialAuthenticationManager(), signUp: SocialSignUp())
        ), profileManager: ProfileAuthenticationManager())
        
        self.appleAuthenticationManager = DecoratorAuthenticationManager(tokenManager: TokenAuthenticationManager(manager: AppleAuthenticationManager()), profileManager: ProfileAuthenticationManager())
        
    }
    
    func signIn(email: String, password: String) -> Observable<()> {
        self.process(profile: self.authenticationManager.authenticated(authentication: DefaultAuthentication(principal: email, credential: password, name: DefaultAuthentication.USERNAME_PASSWORD)))
    }
    
    func signIn(social type: SocialType) -> Observable<()> {
        self.process(profile: self.authenticateSocial(socialType: type, manager: self.socialAuthenticationManager, priority: .signIn))
    }
    
    //sign in apple
    @available(iOS 13.0, *)
    func signIn(credentials: AppleCredential) -> Observable<()>  {
        self.process(profile: authenticationApple(credential: credentials))
    }
    
    func signUp(email: String, password: String) -> Observable<()> {
        self.process(profile: self.signUpManager.authenticated(authentication: DefaultAuthentication(principal: email, credential: password, name: DefaultAuthentication.USERNAME_PASSWORD)))
    }
    
    func signUp(social type: SocialType) -> Observable<()> {
        self.process(profile: self.authenticateSocial(socialType: type, manager: self.socialAuthenticationManager, priority: .signUp))
    }
    
    @available(iOS 13.0, *)
    func authenticationApple(credential:AppleCredential) -> Observable<Authentication> {
        let socialProfile = SocialProfile()
        socialProfile.id = credential.userIdentifier
        socialProfile.email = credential.email ?? ""
        socialProfile.name = credential.fullName ?? ""
        socialProfile.type = SocialType.apple
        return self.appleAuthenticationManager.authenticated(authentication: DefaultAuthentication(principal: socialProfile, credential: "", name: DefaultAuthentication.SOCIAL))
    }
    
    
    
    fileprivate func authenticateSocial(socialType: SocialType, manager: AuthenticationManager, priority: CredentialSocial.Priority) -> Observable<Authentication> {
        var profile: Observable<SocialProfile>
        
        switch socialType {
        case .facebook: profile = FacebookService.shared.login().flatMap { _ in FacebookService.shared.profile() }
        case .google:
            profile = self.googleService.signIn(viewController: (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController ?? UIViewController()).withLatestFrom(Observable.just(self))
                .flatMap { service in
                    Observable
                    .of(service.googleService.profileObservable.map { $0 as Any }, service.googleService.errorObservable.map { $0 as Any })
                    .merge()
                    .flatMap { (value) -> Observable<SocialProfile> in
                        if let profile = value as? SocialProfile {
                            return .just(profile)
                        } else if let error = value as? ServiceError {
                            return .error(error)
                        } else {
                            return .empty()
                        }
                    }
                }
        case .twitter: profile = .empty()
        case .apple: profile = .empty()
        }
        return profile
            .map { DefaultAuthentication(principal: CredentialSocial(profile: $0, priority: priority), credential: "", name: DefaultAuthentication.SOCIAL) }
            .flatMap(manager.authenticated(authentication:))
    }
    
    fileprivate func process(profile: Observable<Authentication>) -> Observable<()> {
        profile.filter { $0.name == DefaultAuthentication.PROFILE && $0.credential is String }
            .do(onNext: { (authentication) in
                guard let token = authentication.credential as? String, !token.isEmpty else { return }
                Session.shared.accessToken = token
                //self.save(authentication: authentication)
            })
            .compactMap { $0.principal as? UserPrivate }
            .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
    }
    
    fileprivate func save(authentication: Authentication) {
        guard let token = authentication.credential as? String, let user = authentication.principal as? UserPrivate, !token.isEmpty else { return }
        let accessToken = AccessTokenEmail(id: user.id, token: token)
        Repository<AccessTokenEmail, AccessTokenObject>.shared.save(object: accessToken).subscribe().disposed(by: self.disposeBag)
    }
    
}
