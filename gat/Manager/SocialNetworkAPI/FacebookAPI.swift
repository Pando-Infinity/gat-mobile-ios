//
//  FacebookAPI.swift
//  gat
//
//  Created by HungTran on 2/25/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON
import FacebookCore
///import XCGLogger

/**Tạo Request lấy thông tin Profile (id, name)*/
//struct ProfileRequest: GraphRequestProtocol {
//    struct Response: GraphResponseProtocol {
//        var id: String!
//        var name: String!
//        var email: String?
//        var image: Data?
//        
//        init(rawResponse: Any?) {
//            let result = JSON(rawResponse!)
//            self.id = result["id"].string
//            self.name = result["name"].string
//            self.email = result["email"].string ?? ""
//            let imageURL = URL(string: "https://graph.facebook.com/" + self.id + "/picture?type=large")
//            self.image = try? Data(contentsOf: imageURL!)
//        }
//    }
//    
//    var graphPath = "/me"
//    var parameters: [String : Any]? = ["fields": "id, name, email"]
//    var accessToken = AccessToken.current
//    var httpMethod: GraphRequestHTTPMethod = .GET
//    var apiVersion: GraphAPIVersion = .defaultVersion
//}
//
//class FacebookAPI: SocialNetworkAPI {
//    /**Cài đặt mẫu SingleTon*/
//    static let sharedAPI = FacebookAPI()
//    
////    let log = XCGLogger.default
//    
//    /**Lấy token đăng nhập của tài khoản mạng xã hội*/
//    func getAuthToken() -> Observable<Result<(String,String)>> {
//        return Observable<Result<(String, String)>>.create { observer in
//            print("Trigger getAuthToken")
//            let loginManager = LoginManager()
//            loginManager.logOut()
////            loginManager.logIn([ .publicProfile, .email ], viewController: nil) { loginResult in
////                switch loginResult {
////                case .failed(let error):
////                    self.log.debug(error)
////                    observer.onNext(Result<(String,String)>.Failure(.Silent("Kiểm tra FB API")))
////                case .cancelled:
////                    self.log.debug("Người dùng bấm nút huỷ bỏ")
////                    observer.onNext(Result<(String,String)>.Failure(.Silent("Người dùng bấm nút Huỷ Bỏ ")))
////                case .success(_, _, let accessToken):
////                    self.log.debug(accessToken)
////                    observer.onNext(Result<(String,String)>.Success(accessToken.authenticationToken, ""))
////                }
////            }
//            return Disposables.create()
//        }
//    }
//    
//    /**Lấy một số public data cần thiết để thực hiện phần đăng ký tài khoản
//    Các data đó bao gồm: id+, type+, name+, email, imageUrl. (+) nghĩa là bắt buộc*/
//    func getPublicData() -> Observable<Result<SocialPublicData>> {
//        return Observable<Result<SocialPublicData>>.create { observer in
//            let connection = GraphRequestConnection()
//            connection.add(ProfileRequest()) { response, result in
//                switch result {
//                case .success(let response):
//                    let socialPublicData = (
//                        id: response.id!,
//                        type: SocialNetworkType.Facebook,
//                        name: response.name!,
//                        email: response.email!,
//                        image: response.image!,
//                        authId: "",
//                        secretToken: (AccessToken.current?.authenticationToken)!
//                    )
//                    observer.onNext(Result<SocialPublicData>.Success(socialPublicData))
//                case .failed(let _):
////                    self.log.debug(error)
//                    observer.onNext(Result<SocialPublicData>.Failure(.Silent("Lỗi Facebook API")))
//                }
//            }
//            connection.start()
//            return Disposables.create()
//        }
//    }
//}
