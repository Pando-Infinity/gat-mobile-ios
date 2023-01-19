//
//  TwitterService.swift
//  gat
//
//  Created by Vũ Kiên on 09/07/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import TwitterKit
import RxSwift
import SwiftyJSON

class TwitterService {
    
    static let shared = TwitterService()
    
    fileprivate init() {
        if let userId = TWTRTwitter.sharedInstance().sessionStore.session()?.userID {
            TWTRTwitter.sharedInstance().sessionStore.logOutUserID(userId)
        }
    }
    
    func token() -> Observable<String> {
        return Observable<String>.create({ (observer) -> Disposable in
            TWTRTwitter.sharedInstance().logIn(completion: { (session, error) in
                if let error = error {
                    observer.onError(ServiceError.init(domain: "Twitter", code: -1, userInfo: ["message": error.localizedDescription]))
                } else if let session = session {
                    observer.onNext(session.authTokenSecret)
                }
            })
            return Disposables.create ()
        })
    }
    
    func profile() -> Observable<SocialProfile> {
        return Observable<JSON>
            .create({ (observer) -> Disposable in
                let client = TWTRAPIClient.withCurrentUser()
                let request = client.urlRequest(withMethod: "GET",
                                                urlString: "https://api.twitter.com/1.1/account/verify_credentials.json",
                                                parameters: ["include_email": "true", "skip_status": "true"],
                                                error: nil)
                client.sendTwitterRequest(request, completion: { (response, data, error) in
                    if let error = error {
                        observer.onError(ServiceError.init(domain: response?.url?.absoluteString ?? "", code: -1, userInfo: ["message": error.localizedDescription]))
                    } else if let data = data {
                        if let json = try? JSON(data: data) {
                            observer.onNext(json)
                        }
                    }
                })
                return Disposables.create()
            })
            .map({ (json) -> SocialProfile in
                let profile = SocialProfile()
                profile.id = "\(json["id"].int ?? -1)"
                profile.name = json["name"].string ?? ""
                profile.email = json["email"].string ?? ""
                if let imageURL = URL(string: json["profile_image_url"].string ?? "") {
                    do {
                        profile.image = try UIImage(data: Data(contentsOf: imageURL))
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                profile.type = .twitter
                return SocialProfile()
            })
    }
}
