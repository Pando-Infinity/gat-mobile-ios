//
//  LoginPresenter.swift
//  gat
//
//  Created by jujien on 5/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa


protocol LoginPresenter {
    
    var loading: Observable<Bool> { get }
    
    func signIn(credentials: Credentials) -> Observable<()>
    
    func signIn(social type: SocialType) -> Observable<()>
    
    func showError()
    
    @available(iOS 13.0, *)
    func signInApple()
}


struct SimpleLoginPresenter: LoginPresenter {
    
    var loading: Observable<Bool> { self.isLoading.asObservable() }
    
    fileprivate let isLoading: BehaviorRelay<Bool> = .init(value: false)
    
    fileprivate let authenticationUsecase: AuthenticationUseCase = DefaultAuthenticationUseCase()
    
    fileprivate let router: LoginRouter
    
    fileprivate let error = BehaviorRelay<Error?>(value: nil)
    
    init(router: LoginRouter) {
        self.router = router
    }
    
    func signIn(credentials: Credentials) -> Observable<()> {
        self.error.accept(nil)
        guard !credentials.email.isEmpty, credentials.email.isValidEmail(), !credentials.password.isEmpty else { return .empty() }
        self.isLoading.accept(true)
        return self.authenticationUsecase.signIn(email: credentials.email, password: credentials.password)
            .catchError(self.handle(error:))
            .do(onNext: self.handleSuccess)
    }
    
    func signIn(social type: SocialType) -> Observable<()> {
        self.error.accept(nil)
        self.isLoading.accept(true)
        return self.authenticationUsecase.signIn(social: type)
            .catchError(self.handle(error:))
            .do(onNext: self.handleSuccess)
    }
    
    func signInApple() { }
    
    func showError() {
        guard let error = self.error.value else { return }
        self.router.showAlertError(error)
    }
    
}

extension SimpleLoginPresenter {
    fileprivate func handle(error: Error) -> Observable<()> {
        if let error = error as? RxError {
            print("\(error): \(error.localizedDescription)")
        }
        self.isLoading.accept(false)
        self.error.accept(error)
        return .empty()
    }
    
    fileprivate func handleSuccess() {
        self.isLoading.accept(false)
        FirebaseBackground.shared.registerFirebaseToken()
        self.router.gotoHome()
    }
}


@available(iOS 13.0, *)
struct AppleLoginPresenter:LoginPresenter{
    
    var loading: Observable<Bool> { self.isLoading.asObservable() }
    
    fileprivate let isLoading: BehaviorRelay<Bool> = .init(value: false)
    
    fileprivate let authenticationApple: AppleAuthenticationService = DefaultAppleAuthenticationService()
    
    fileprivate let authenticationUsecase: AuthenticationUseCase = DefaultAuthenticationUseCase()
    
    fileprivate let router: LoginRouter
    
    fileprivate let error = BehaviorRelay<Error?>(value:nil)
    
    fileprivate let providing = DefaultASAuthorizationControllerPresentationContextProviding()
    
    fileprivate let disposeBag = DisposeBag()
    
    init(router:LoginRouter) {
        self.router = router
        
        self.authenticationApple.existPasswordCredential.withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
            .flatMap { (credentials, presenter) -> Observable<()> in
                presenter.signIn(credentials: credentials)
        }
        .subscribe()
        .disposed(by: disposeBag)
        
        self.authenticationApple.appleIDCredentials.withLatestFrom(Observable.just(self), resultSelector: { ($0,$1) })
            .do(onNext: { (_, presenter) in
                presenter.error.accept(nil)
                presenter.isLoading.accept(true)
            })
            .flatMap{ (credentials,presenter) -> Observable<()> in
                presenter.authenticationUsecase.signIn(credentials: credentials)
                    .catchError(presenter.handle(error:))
        }
        .subscribe(onNext: self.handleSuccess)
        .disposed(by: disposeBag)

    }
    
    func signIn(credentials: Credentials) -> Observable<()> {
        self.error.accept(nil)
        guard !credentials.email.isEmpty, credentials.email.isValidEmail(), !credentials.password.isEmpty else { return .empty() }
        self.isLoading.accept(true)
        return self.authenticationUsecase.signIn(email: credentials.email, password: credentials.password)
            .catchError(self.handle(error:))
            .do(onNext: self.handleSuccess)
    }
    
    func signIn(social type: SocialType) -> Observable<()> {
        self.error.accept(nil)
        self.isLoading.accept(true)
        return self.authenticationUsecase.signIn(social: type)
            .catchError(self.handle(error:))
            .do(onNext: self.handleSuccess)
    }
    
    func showError() {
        guard let error = self.error.value else { return }
        self.router.showAlertError(error)
    }
    
    func signInApple() {
        self.authenticationApple.request(presentationContextProvider: self.providing)
    }
}


@available(iOS 13.0, *)
extension AppleLoginPresenter {
    fileprivate func handle(error: Error) -> Observable<()> {
        if let error = error as? RxError {
            print("\(error): \(error.localizedDescription)")
        }
        self.isLoading.accept(false)
        self.error.accept(error)
        return .empty()
    }
    
    fileprivate func handleSuccess() {
        self.isLoading.accept(false)
        FirebaseBackground.shared.registerFirebaseToken()
        self.router.gotoHome()
    }
}

