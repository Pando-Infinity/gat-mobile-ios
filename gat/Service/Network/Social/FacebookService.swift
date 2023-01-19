//  FacebookService.swift
//  gat
//
//  Created by Vũ Kiên on 09/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import RxSwift
import FacebookCore
import FBSDKLoginKit
import SDWebImage
import SwiftyJSON

class FacebookService {
    
    static let shared = FacebookService()
    
    let token: BehaviorSubject<String> = .init(value: "")
    fileprivate let loginManager: LoginManager
    
    fileprivate init() {
        self.loginManager = LoginManager()
    }
    
    func login() -> Observable<String> {
        return Observable<LoginManager>
            .just(self.loginManager)
            .flatMap { [weak self] (loginManager) -> Observable<String> in
                return Observable<String>
                    .create({ [weak self] (observer) -> Disposable in
                        loginManager.logIn(permissions: [Permission.publicProfile, Permission.email], viewController: UIApplication.topViewController()!, completion: { [weak self] (result) in
                            switch result {
                            case .failed(let error):
                                print(error.localizedDescription)
                                observer.onError(ServiceError(domain: "Failed!!", code: -1, userInfo: ["message": error.localizedDescription]))
                                break
                            case .cancelled:
                                print("Cancel")
                                observer.onError(ServiceError(domain: "Failed!!", code: -1, userInfo: ["message": "Cancelled"]))
                                break
                            case .success(_, _, let token):
                                observer.onNext(token.tokenString)
                                self?.token.onNext(token.tokenString)
                                break
                            }

                        })
                        return Disposables.create()
                    })
        }
    }
    
    func logout() -> Observable<()> {
        return Observable<LoginManager>.just(self.loginManager).flatMap { (loginManager) -> Observable<()> in
            loginManager.logOut()
            return Observable<()>.just(())
        }
    }
    
    func profile() -> Observable<SocialProfile> {
        return Observable<GraphRequest>
            .just(GraphRequest(graphPath: "me", parameters: ["fields":"id, email, name, picture.width(480).height(480)"])).flatMap { (request) -> Observable<SocialProfile> in
                return Observable<SocialProfile>.create({ (observer) -> Disposable in
                    request.start(completionHandler: { (connect, result, error) in
                        if let error = error {
                            print(error.localizedDescription)
                            observer.onError(ServiceError(domain: "Failed!!", code: -1, userInfo: ["message": error.localizedDescription]))
                        } else if let result = result {
                            let json = JSON(result)
                            let profile = SocialProfile()
                            profile.email = json["email"].string ?? ""
                            profile.name = json["name"].string ?? ""
                            profile.id = json["id"].string ?? ""
                            if let path = json["picture"]["data"]["url"].string, let url = URL(string: path), let data = try? Data.init(contentsOf: url) {
                                profile.image = UIImage(data: data)
                            }
                            profile.type = .facebook
                            observer.onNext(profile)
                        }
                    })
                    return Disposables.create()
                })
        }
    }
}
