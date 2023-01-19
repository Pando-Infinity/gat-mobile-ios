//
//  AppleAuthenticationService.swift
//  gat
//
//  Created by jujien on 7/11/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import AuthenticationServices
import RxSwift

@available(iOS 13.0, *)
protocol AppleAuthenticationService {
    
    var authorization: Observable<ASAuthorization> { get }
    
    var error: Observable<ASAuthorizationError> { get }
    
    func request(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?)
}

@available(iOS 13.0, *)
extension AppleAuthenticationService {
    var credentials: Observable<ASAuthorizationCredential> { self.authorization.map { $0.credential } }
    
    var existPasswordCredential: Observable<Credentials> {
        self.credentials.compactMap { $0 as? ASPasswordCredential }.map { Credentials(email: $0.user, password: $0.password) }
    }
    
    var appleIDCredentials: Observable<AppleCredential> {
        self.credentials.compactMap { $0 as? ASAuthorizationAppleIDCredential }.map { (appleIDCredential) -> AppleCredential in
            var fullName: String?
            if let full = appleIDCredential.fullName {
                if let giveName = full.givenName {
                    fullName = giveName
                }
                if let familyName = full.familyName {
                    if fullName != nil {
                        fullName?.append(" \(familyName)")
                    } else {
                        fullName = familyName
                    }
                }
            }
            return .init(userIdentifier: appleIDCredential.user, email: appleIDCredential.email, fullName: fullName)
        }
    }
}

@available(iOS 13.0, *)
class DefaultAppleAuthenticationService: AppleAuthenticationService {
    
    var authorization: Observable<ASAuthorization> { self._authorization }
    
    var error: Observable<ASAuthorizationError> { self._error }
    
    fileprivate let controller: ASAuthorizationController
    fileprivate let _authorization: Observable<ASAuthorization>
    fileprivate let _error: Observable<ASAuthorizationError>
    
    init() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        self.controller = ASAuthorizationController(authorizationRequests: [request])
        self._authorization = self.controller.rx.didAuthorized.asObservable().share().subscribeOn(MainScheduler.asyncInstance).do(onNext: { print($0) })
        self._error = self.controller.rx.didCompleteError.map { ASAuthorizationError(_nsError: $0 as NSError) }.share().subscribeOn(MainScheduler.asyncInstance).do(onNext: { print($0) })
    }
    
    func request(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?) {
        self.controller.presentationContextProvider = presentationContextProvider
        self.controller.performRequests()
    }
}

@available(iOS 13.0, *)
struct AppleCredential {
    var userIdentifier: String
    var email: String?
    var fullName: String?
}

@available(iOS 13.0, *)
class DefaultASAuthorizationControllerPresentationContextProviding: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return (UIApplication.shared.delegate as? AppDelegate)?.window ?? UIWindow(frame: UIScreen.main.bounds)
    }
    
    
}
