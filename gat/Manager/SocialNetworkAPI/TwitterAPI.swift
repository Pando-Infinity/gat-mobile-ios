//
//  TwitterAPI.swift
//  gat
//
//  Created by HungTran on 5/1/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import TwitterKit
import SwiftyJSON
//import XCGLogger

class TwitterAPI: SocialNetworkAPI {
    
    /**Cài đặt mẫu SingleTon*/
    static let sharedAPI = TwitterAPI()
//    let log = XCGLogger.default
    var authId: String = ""
    var secretToken: String = ""
    
    /**Lấy token đăng nhập của tài khoản mạng xã hội*/
    func getAuthToken() -> Observable<Result<(String, String)>> {
        if let userId = TWTRTwitter.sharedInstance().sessionStore.session()?.userID {
            TWTRTwitter.sharedInstance().sessionStore.logOutUserID(userId)
        }
        return Observable<Result<(String, String)>>.create { observer in
            TWTRTwitter.sharedInstance().logIn () { session, error in
                if let _ = error {
                    observer.onNext(Result<(String, String)>.Failure(.Silent("Kiểm tra Twitter API")))
                } else {
                    if (session != nil) {
                        self.authId = (session?.authToken)!
                        self.secretToken = (session?.authTokenSecret)!
                        let result = (self.authId, self.secretToken)
                        observer.onNext(Result<(String, String)>.Success(result))
                    } else {
                        observer.onNext(Result<(String, String)>.Failure(.Silent("Kiểm tra Twitter API")))
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    /**Lấy một số public data cần thiết để thực hiện phần đăng ký tài khoản
     Các data đó bao gồm: id+, type+, name+, email, imageUrl. (+) nghĩa là bắt buộc*/
    func getPublicData() -> Observable<Result<SocialPublicData>> {
        return Observable<Result<SocialPublicData>>.create { observer in
            
            let client = TWTRAPIClient.withCurrentUser()
            let request = client.urlRequest(withMethod: "GET",
                                            urlString: "https://api.twitter.com/1.1/account/verify_credentials.json",
                                                      parameters: ["include_email": "true", "skip_status": "true"],
                                                      error: nil)
            client.sendTwitterRequest(request) { response, data, connectionError in
                if let data = data, let user = try? JSON(data: data) {
                    let imageURL = URL(string: user["profile_image_url"].string ?? "")
                    let image = try? Data(contentsOf: imageURL!)
                    let socialPublicData: SocialPublicData = (
                        id: String(user["id"].int ?? -1),
                        type: SocialNetworkType.Twitter,
                        name: user["name"].string ?? "",
                        email: user["email"].string ?? "",
                        image: image!,
                        authId: self.authId,
                        secretToken: self.secretToken
                    )
                    observer.onNext(Result<SocialPublicData>.Success(socialPublicData))
                } else {
                    observer.onNext(Result<SocialPublicData>.Failure(.Silent("Kiểm tra Twitter API")))
                }
            }
            return Disposables.create()
        }
    }
}
