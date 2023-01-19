//
//  FirebaseService.swift
//  gat
//
//  Created by Vũ Kiên on 07/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Firebase
import RxSwift

class FirebaseService {
    
    static var shared = FirebaseService()
    
    fileprivate init() {
        
    }
    
//    func create(email: String, password: String) -> Observable<FIRUser> {
//        return Observable<FIRUser>.create { (observer) -> Disposable in
//            FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
//                if let error = error {
//                    observer.onError(ServiceError.init(domain: "FIRAuth", code: 0, userInfo: ["message": error.localizedDescription]))
//                }
//                if let user = user {
//                    observer.onNext(user)
//                }
//            })
//            return Disposables.create()
//        }
//    }
//    
    func signIn(email: String, password: String) -> Observable<Firebase.User> {
        return Observable<Firebase.User>.create { (observer) -> Disposable in
            Firebase.Auth.auth().signIn(withEmail: email, password: password, completion: { (result, error) in
                if let error = error {
                    observer.onError(ServiceError(domain: "FIRAuth", code: 0, userInfo: ["message": error.localizedDescription]))
                }
                if let user = result?.user {
                    observer.onNext(user)
                }
            })
            return Disposables.create()
        }
    }
//
//    func signIn(with authCredential: FIRAuthCredential) -> Observable<FIRUser> {
//        return Observable<FIRUser>.create({ (observer) -> Disposable in
//            FIRAuth.auth()?.signIn(with: authCredential, completion: { (user, error) in
//                if let error = error {
//                    observer.onError(ServiceError(domain: "FIRAuth", code: 0, userInfo: ["message": error.localizedDescription]))
//                }
//                if let user = user {
//                    observer.onNext(user)
//                }
//            })
//            return Disposables.create()
//        })
//    }
//    
//    func linkByUser(email: String, password: String) {
//        if let user = FIRAuth.auth()?.currentUser {
//            let credential = FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
//            user.link(with: credential) { (user, error) in
//                if let error = error {
//                    print("error: ", error.localizedDescription)
//                }
//            }
//        } else {
//            print("Chưa login Firebase (link account với email và password)")
//        }
//    }
//    
//    func linkBySocial(registerType: RegisterType) -> Observable<()> {
//        return Observable<RegisterType>
//            .just(registerType)
//            .flatMap { (type) -> Observable<FIRAuthCredential> in
//                switch type {
//                case .facebook(_, let token):
//                    return Observable.just(FIRFacebookAuthProvider.credential(withAccessToken: token))
//                case .google(let profile, let token):
//                    return Observable.just(FIRGoogleAuthProvider.credential(withIDToken: profile.id, accessToken: token))
//                case .twitter(_, let token):
//                    return Observable.empty()
//                default:
//                    return Observable.empty()
//                }
//            }
//            .flatMap { (credential) -> Observable<()> in
//                return Observable<()>.create({ (observer) -> Disposable in
//                    if let user = FIRAuth.auth()?.currentUser {
//                        user.link(with: credential, completion: { (user, error) in
//                            if let error = error {
//                                observer.onError(ServiceError.init(domain: "", code: -1, userInfo: ["message": error.localizedDescription]))
//                            } else {
//                                observer.onNext(())
//                            }
//                        })
//                    } else {
//                        print("Chưa login Firebase (link account với email và password)")
//                    }
//                    return Disposables.create()
//                })
//            }
//    }
//    
//    func unlink(social: SocialType) -> Observable<()> {
//        return Observable<()>.create({ (observer) -> Disposable in
//            var socialProviderId = ""
//            switch social {
//            case .facebook:
//                socialProviderId = "facebook.com"
//                break
//            case .google:
//                socialProviderId = "google.com"
//                break
//            case .twitter:
//                socialProviderId = "twitter.com"
//                break
//            }
//            if let user = FIRAuth.auth()?.currentUser {
//                user.unlink(fromProvider: socialProviderId, completion: { (user, error) in
//                    if let error = error {
//                        observer.onError(ServiceError.init(domain: "", code: -1, userInfo: ["message": error.localizedDescription]))
//                    } else {
//                        observer.onNext(())
//                    }
//                })
//            } else {
//                observer.onError(ServiceError.init(domain: "", code: -1, userInfo: ["message": "Error"]))
//            }
//            return Disposables.create()
//        })
//    }
}
