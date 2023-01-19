////
////  TwitterAPI.swift
////  gat
////
////  Created by HungTran on 5/1/17.
////  Copyright © 2017 GaTBook. All rights reserved.
////
//
//import Foundation
//import RxSwift
//import SwiftyJSON
////import XCGLogger
//
//class GoogleAPI: UIViewController, SocialNetworkAPI, GIDSignInUIDelegate, GIDSignInDelegate {
//    
//    /**Cài đặt mẫu SingleTon*/
//    static let sharedAPI = GoogleAPI()
//    
////    let log = XCGLogger.default
//    
//    private var authTokenStream: Variable<Result<(String, String)>?> = Variable(nil)
//    private var publicDataStream: Variable<Result<SocialPublicData>?> = Variable(nil)
//    private var currentEvent: Int = -1
//    
//    private func setupDelegate() {
//        GIDSignIn.sharedInstance().delegate = self
//        GIDSignIn.sharedInstance().uiDelegate = self
//    }
//    
//    /**Lấy token đăng nhập của tài khoản mạng xã hội*/
//    func getAuthToken() -> Observable<Result<(String, String)>> {
//        setupDelegate()
//        self.currentEvent = 1
//        GIDSignIn.sharedInstance().signOut()
//        GIDSignIn.sharedInstance().signIn()
//        
//        return authTokenStream.asObservable().filter({ (data) -> Bool in
//            return data != nil
//        }).flatMapLatest({ (data) -> Observable<Result<(String, String)>> in
//            return Observable.just(data!)
//        }).elementAt(0)
//    }
//    
//    /**Lấy một số public data cần thiết để thực hiện phần đăng ký tài khoản
//     Các data đó bao gồm: id+, type+, name+, email, imageUrl. (+) nghĩa là bắt buộc*/
//    func getPublicData() -> Observable<Result<SocialPublicData>> {
//        setupDelegate()
//        self.currentEvent = 2
//        GIDSignIn.sharedInstance().signOut()
//        GIDSignIn.sharedInstance().signIn()
//        
//        return publicDataStream.asObservable().filter({ (data) -> Bool in
//            return data != nil
//        }).flatMapLatest({ (data) -> Observable<Result<SocialPublicData>> in
//            return Observable.just(data!)
//        }).elementAt(0)
//    }
//    
//    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
//        let vc = UIApplication.topViewController()
//        vc?.present(viewController, animated: true, completion: nil)
//    }
//    
//    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
//        UIApplication.topViewController()?.dismiss(animated: true, completion: nil)
//    }
//    
//    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        switch currentEvent {
//        case 1:
//            authTokenStream.value = Result<(String,String)>.Success(((user.authentication.idToken)!, (user.authentication.accessToken)!))
//        case 2:
//            if user == nil {
//                publicDataStream.value = Result<SocialPublicData>.Failure(.Silent("Người dùng bấm huỷ bỏ"))
//            } else {
//                let imageURL = URL(string: user.profile.imageURL(withDimension: 200).absoluteString)
//                let image = try? Data(contentsOf: imageURL!)
//                let socialPublicData: SocialPublicData = (
//                    id: user.userID,
//                    type: SocialNetworkType.Google,
//                    name: user.profile.name,
//                    email: user.profile.email,
//                    image: image!,
//                    authId: user.authentication.idToken,
//                    secretToken: user.authentication.accessToken
//                )
//                publicDataStream.value = Result<SocialPublicData>.Success(socialPublicData)
//            }
//        default: break
//        }
//        self.currentEvent = -1
//    }
//}
