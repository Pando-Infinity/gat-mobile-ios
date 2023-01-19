//
//  GoogleService.swift
//  gat
//
//  Created by Vũ Kiên on 09/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import GoogleSignIn
import RxSwift

class GoogleService: NSObject {
    
    static let shared = GoogleService()
    
    var profileObservable: Observable<SocialProfile> {
        return self.profile.filter { !$0.id.isEmpty }
    }
    
    var tokenObservable: Observable<String> {
        return self.token.filter { !$0.isEmpty }
    }
    
    var errorObservable: Observable<Error?> { return self.error.filter { $0 != nil } }
    
    fileprivate let profile = BehaviorSubject<SocialProfile>(value: SocialProfile())
    fileprivate let error = BehaviorSubject<Error?>(value: nil)
    fileprivate let token = BehaviorSubject<String>(value: "")
    let google: GIDSignIn
    
    override init() {
        self.google = GIDSignIn.sharedInstance
        super.init()
    }
    
    func signIn(viewController: UIViewController) -> Observable<()> {
        self.error.onNext(nil)
        self.profile.onNext(.init())
        guard let clientId = AppConfig.sharedConfig.config(item: "google_clien_id") else { return .empty() }
        self.google.signIn(with: GIDConfiguration(clientID: clientId), presenting: viewController) { user, error in
            if let userID = user?.userID, let fullName = user?.profile?.name, let email = user?.profile?.email, let imageUrl = user?.profile?.imageURL(withDimension: 480) {
                let profile = SocialProfile()
                profile.email = email
                profile.name = fullName
                profile.id = userID
                do {
                    profile.image = try UIImage(data: Data(contentsOf: imageUrl))
                } catch {
                    print(ServiceError(domain: error.localizedDescription, code: -1, userInfo: ["message": error.localizedDescription]))
                }
                profile.type = .google
                self.profile.onNext(profile)
            }
            if let error = error {
                let e = ServiceError(domain: error.localizedDescription, code: -1, userInfo: ["message": error.localizedDescription])
                self.error.onNext(e)
            }
        }
        self.token.onNext("")
        return Observable<()>.just(())
    }
    
//    func sign(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
//        if let token = user?.authentication.accessToken {
//            self.token.onNext(token)
//        }
//        if let userID = user?.userID, let fullName = user?.profile.name, let email = user?.profile.email, let imageUrl = user?.profile.imageURL(withDimension: 480) {
//            let profile = SocialProfile()
//            profile.email = email
//            profile.name = fullName
//            profile.id = userID
//            do {
//                profile.image = try UIImage(data: Data(contentsOf: imageUrl))
//            } catch {
//                print(ServiceError(domain: error.localizedDescription, code: -1, userInfo: ["message": error.localizedDescription]))
//            }
//            profile.type = .google
//            self.profile.onNext(profile)
//        }
//        if let error = error {
//            let e = ServiceError(domain: error.localizedDescription, code: -1, userInfo: ["message": error.localizedDescription])
//            self.error.onNext(e)
//        }
//    }
//
//    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
//        let e = ServiceError(domain: error.localizedDescription, code: -1, userInfo: ["message": error.localizedDescription])
//        self.error.onNext(e)
//    }
    
    
}
