//
//  AppleAuthenticationDelegate.swift
//  gat
//
//  Created by jujien on 7/11/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AuthenticationServices


@available(iOS 13.0, *)
final class RxASAuthorizationControllerDelegateProxy: DelegateProxy<ASAuthorizationController, ASAuthorizationControllerDelegate>, ASAuthorizationControllerDelegate, DelegateProxyType {
    
    weak private(set) var controller: ASAuthorizationController?
    
    init(controller: ASAuthorizationController) {
        self.controller = controller
        super.init(parentObject: controller, delegateProxy: RxASAuthorizationControllerDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register(make: { RxASAuthorizationControllerDelegateProxy(controller: $0) })
    }
    
    static func currentDelegate(for object: ASAuthorizationController) -> ASAuthorizationControllerDelegate? {
        let controller = object
        return controller.delegate
    }
    
    static func setCurrentDelegate(_ delegate: ASAuthorizationControllerDelegate?, to object: ASAuthorizationController) {
        let controller = object
        controller.delegate = delegate
    }
}

@available(iOS 13.0, *)
extension Reactive where Base: ASAuthorizationController {
    var delegate: DelegateProxy<ASAuthorizationController, ASAuthorizationControllerDelegate> {
        return RxASAuthorizationControllerDelegateProxy.proxy(for: self.base)
    }
    
    var didAuthorized: Observable<ASAuthorization> {
        self.delegate.methodInvoked(#selector(ASAuthorizationControllerDelegate.authorizationController(controller:didCompleteWithAuthorization:)))
        .compactMap { $0.last as? ASAuthorization}
    }
    
    var didCompleteError: Observable<Error> {
        self.delegate.methodInvoked(#selector(ASAuthorizationControllerDelegate.authorizationController(controller:didCompleteWithError:)))
        .compactMap { $0.last as? Error }
    }
}

@available(iOS 13.0, *)
extension ASAuthorizationController: HasDelegate {
    
}
