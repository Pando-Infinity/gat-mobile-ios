//
//  FirebaseBackground.swift
//  gat
//
//  Created by Vũ Kiên on 14/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import Firebase

class FirebaseBackground {
    
    static let shared = FirebaseBackground()
    
    fileprivate let disposeBag: DisposeBag
    
    fileprivate init() {
        self.disposeBag = .init()
    }
    
    func registerFirebaseToken() {
        CommonNetworkService.shared.startApp(uuid: UIDevice.current.identifierForVendor?.uuidString ?? "").subscribe().disposed(by: self.disposeBag)
        MessageService.shared.configure()
        FirebaseService.shared.signIn(email: "noreply@gatbook.org", password: "GaT20171222")
            .catchError({ (error) -> Observable<Firebase.User> in
                return Observable.empty()
            })
            .flatMap { (_) -> Observable<String> in
                return Observable<String>.create { (observer) -> Disposable in
                    Messaging.messaging().token { result, error in
                        if let token = result {
                            observer.onNext(token)
                            print(token)
                        }
                    }
                    return Disposables.create()
                }
            }
            .map { ($0, UIDevice.current.identifierForVendor?.uuidString ?? "") }
            .flatMap {
                return UserNetworkService.shared
                    .registerFirebase(token: $0, uuid: $1)
                    .catchError { (error) -> Observable<()> in
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                }
            }
        .subscribe()
            .disposed(by: self.disposeBag)
    }
}
