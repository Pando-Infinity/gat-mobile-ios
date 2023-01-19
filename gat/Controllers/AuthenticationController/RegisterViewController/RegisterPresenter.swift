//
//  RegisterPresenter.swift
//  gat
//
//  Created by jujien on 5/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol RegisterPresenter {
    var loading: Observable<Bool> { get }
    
    func signUp(credentials: Credentials) -> Observable<()>
    
    func signUp(social type: SocialType) -> Observable<()>
    
    @available(iOS 13.0, *)
    func signInApple()
    
}

struct SimpleRegisterPresenter: RegisterPresenter {
    
    var loading: Observable<Bool> { self.isLoading.asObservable() }
    
    fileprivate let isLoading: BehaviorRelay<Bool> = .init(value: false)
    
    fileprivate let authenticationUsecase: AuthenticationUseCase = DefaultAuthenticationUseCase()
    
    fileprivate let router: RegisterRouter
    
    init(router: RegisterRouter) {
        self.router = router
    }
    
    func signInApple() {
    }
    
    func signUp(credentials: Credentials) -> Observable<()> {
        guard !credentials.email.isEmpty && credentials.email.isValidEmail() && !credentials.password.isEmpty && credentials.password == credentials.confirmPassword else { return .empty() }
        self.isLoading.accept(true)
        return self.authenticationUsecase.signUp(email: credentials.email, password: credentials.password)
            .catchError(self.handle(error:))
            .do(onNext: self.handleSuccess)
    }
    
    func signUp(social type: SocialType) -> Observable<()> {
        self.authenticationUsecase.signUp(social: type)
            .catchError(self.handle(error:))
            .do(onNext: self.handleSuccess)
    }
    
}

extension SimpleRegisterPresenter {
    fileprivate func handle(error: Error) -> Observable<()> {
        self.isLoading.accept(false)
        self.router.showAlertError(error)
        return .empty()
    }
    
    fileprivate func handleSuccess() {
        self.isLoading.accept(false)
        FirebaseBackground.shared.registerFirebaseToken()
        self.router.gotoHome()
    }
}


@available(iOS 13.0, *)
struct AppleSimpleRegisterPresenter: RegisterPresenter {

    var loading: Observable<Bool> { self.isLoading.asObservable() }

    fileprivate let isLoading: BehaviorRelay<Bool> = .init(value: false)

    fileprivate let authenticationApple: AppleAuthenticationService = DefaultAppleAuthenticationService()

    fileprivate let authenticationUsecase: AuthenticationUseCase = DefaultAuthenticationUseCase()

    fileprivate let providing = DefaultASAuthorizationControllerPresentationContextProviding()

    fileprivate let router: RegisterRouter

    fileprivate let disposeBag = DisposeBag()

    init(router: RegisterRouter) {
        self.router = router

        self.authenticationApple.existPasswordCredential.withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
            .flatMap { (credentials, presenter) -> Observable<()> in
                presenter.signUp(credentials: credentials)
        }
        .subscribe()
        .disposed(by: disposeBag)

        self.authenticationApple.appleIDCredentials.withLatestFrom(Observable.just(self), resultSelector: { ($0,$1) })
            .do(onNext: { (_, presenter) in
                presenter.isLoading.accept(true)
            })
            .flatMap{ (credentials,presenter) -> Observable<()> in
                presenter.authenticationUsecase.signIn(credentials: credentials)
                    .catchError(presenter.handle(error:))
        }
        .subscribe(onNext: self.handleSuccess)
        .disposed(by: disposeBag)
    }

    func signInApple() {
        self.authenticationApple.request(presentationContextProvider: self.providing)
    }

    func signUp(credentials: Credentials) -> Observable<()> {
        guard !credentials.email.isEmpty && credentials.email.isValidEmail() && !credentials.password.isEmpty && credentials.password == credentials.confirmPassword else { return .empty() }
        self.isLoading.accept(true)
        return self.authenticationUsecase.signUp(email: credentials.email, password: credentials.password)
            .catchError(self.handle(error:))
            .do(onNext: self.handleSuccess)
    }

    func signUp(social type: SocialType) -> Observable<()> {
        self.authenticationUsecase.signUp(social: type)
            .catchError(self.handle(error:))
            .do(onNext: self.handleSuccess)
    }

}


@available(iOS 13.0, *)
extension AppleSimpleRegisterPresenter {
    fileprivate func handle(error: Error) -> Observable<()> {
        self.isLoading.accept(false)
        self.router.showAlertError(error)
        return .empty()
    }

    fileprivate func handleSuccess() {
        self.isLoading.accept(false)
        FirebaseBackground.shared.registerFirebaseToken()
        self.router.gotoHome()
    }
}
