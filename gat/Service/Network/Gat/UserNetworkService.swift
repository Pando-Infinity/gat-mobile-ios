//
//  UserService.swift
//  gat
//
//  Created by Vũ Kiên on 23/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON
import Alamofire

enum LoginType {
    case email(String, String)
    case facebook(String)
    case google(String)
    case twitter(String)
    case apple(String)
}

enum RegisterType {
    case email(String, String)
    case facebook(SocialProfile, String)
    case google(SocialProfile, String)
    case twitter(SocialProfile, String)
    case apple(SocialProfile, String)
}

class UserNetworkService {
    static var shared: UserNetworkService = UserNetworkService()
    
    fileprivate let dispatcher: Dispatcher
    
    fileprivate let searchDispatcher: Dispatcher
    
    fileprivate var service: ServiceNetwork
    var progress: Observable<Double> {
        return self.service.progress.asObserver()
    }
    
    fileprivate init() {
        self.dispatcher = APIDispatcher()
        self.searchDispatcher = SearchDispatcher()
        self.service = ServiceNetwork.shared
    }
    
    func register(type: RegisterType, uuid: String) -> Observable<(String, String?)> {
        service.builder().method(.post)
        switch type {
        case .email(let email, let password):
            guard let name = email.components(separatedBy: "@").first else {
                return Observable.error(ServiceError(domain: "", code: -1, userInfo: ["message": "Không phải email"]))
            }
            service
                .setPathUrl(path: "user/register_by_email")
                .with(parameters: ["email": email, "name": name, "password": password, "uuid": uuid])
            break
        case .facebook(let profile, let password):
            service
                .setPathUrl(path: "user/register_by_social")
                .with(parameters: ["socialID": profile.id, "Image": profile.image?.toBase64() ?? "", "socialType": profile.type.rawValue, "name": profile.name, "email": profile.email, "password": password, "uuid": uuid])
            break
        case .google(let profile, let password):
            service
                .setPathUrl(path: "user/register_by_social")
                .with(parameters: ["socialID": profile.id, "Image": profile.image?.toBase64() ?? "", "socialType": profile.type.rawValue, "name": profile.name, "email": profile.email, "password": password, "uuid": uuid])
            break
        case .twitter(let profile, let password):
            service
                .setPathUrl(path: "user/register_by_social")
                .with(parameters: ["socialID": profile.id, "Image": profile.image?.toBase64() ?? "", "socialType": profile.type.rawValue, "name": profile.name, "email": profile.email, "password": password, "uuid": uuid])
        case .apple(let profile, let password):
            service
                .setPathUrl(path: "user/register_by_social")
                .with(parameters: ["socialID": profile.id, "Image": profile.image?.toBase64() ?? "", "socialType": profile.type.rawValue, "name": profile.name, "email": profile.email, "password": password, "uuid": uuid])
            break
        }
        return service
            .request()
            .map({ (json) -> (String, String?) in
                print(json)
                let data = json["data"]
                let loginToken = data["loginToken"].string ?? ""
                let firebasePassword = data["firebasePassword"].string
                return (loginToken, firebasePassword)
            })
    }
    
    func register(email: String, password: String, uuid: String) -> Observable<DataTokenResponse> {
        self.dispatcher.fetch(request: UsernamePasswordSignUpRequest(email: email, password: password, uuid: uuid), handler: TokenResponse())
    }
    
    func register(social: SocialProfile, password: String, uuid: String) -> Observable<DataTokenResponse> {
        self.dispatcher.fetch(request: SocialSignUpRequest(profile: social, password: password, uuid: uuid), handler: TokenResponse())
    }
    
    func registerFirebase(token: String, uuid: String) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .method(.post)
                    .setPathUrl(path: "user/firebase_token_register")
                    .with(parameters: ["firebaseToken": token, "uuid": uuid])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> () in
                print("JSON REG: \(json)")
                return ()
            })
    }
    
    func login(with type: LoginType, uuid: String) -> Observable<(String, String?, UserType)> {
        self.service
            .builder()
            .method(.post)
        switch type {
        case .email(let email, let password):
            self.service
                .setPathUrl(path: "user/login_by_email")
                .with(parameters: ["email": email, "password": password, "uuid": uuid])
            break
        case .facebook(let userId):
            self.service
                .setPathUrl(path: "user/login_by_social")
                .with(parameters: ["socialID": userId, "socialType": 1, "uuid": uuid])
            break
        case .google(let userId):
            self.service
                .setPathUrl(path: "user/login_by_social")
                .with(parameters: ["socialID": userId, "socialType": 2,  "uuid": uuid])
            break
        case .twitter(let userId):
            self.service
                .setPathUrl(path: "user/login_by_social")
                .with(parameters: ["socialID": userId, "socialType": 3,  "uuid": uuid])
        case .apple(let userId):
            self.service
                .setPathUrl(path: "user/login_by_social")
                .with(parameters: ["socialID": userId, "socialType": 4,  "uuid": uuid])
            break
        }
        
        return self.service
            .request()
            .flatMap({ (json) -> Observable<(String, String?, UserType)> in
                print(json)
                let data = json["data"]
                let loginToken = data["loginToken"].string ?? ""
                let firebasePassword = data["firebasePassword"].string
                let userTypeFlag = UserType(rawValue: data["userTypeFlag"].int ?? 0) ?? .normal
                return Observable<(String, String?, UserType)>.just((loginToken, firebasePassword, userTypeFlag))
            })
    }
    
    func login(email: String, password: String, uuid: String) -> Observable<DataTokenResponse> {
        self.dispatcher.fetch(request: UsernamePasswordSignInRequest(email: email, password: password, uuid: uuid), handler: TokenResponse())
    }
    
    func login(social: SocialProfile, uuid: String) -> Observable<DataTokenResponse> {
        self.dispatcher.fetch(request: SocialSignInRequest(socialID: social.id, socialType: social.type.rawValue, uuid: uuid), handler: TokenResponse())
    }
    
    func loginApple(social: SocialProfile, uuid: String) -> Observable<DataTokenResponse> {
        self.searchDispatcher.fetch(request: AppleSignInRequest(socialID: social.id, socialType: social.type.rawValue, uuid: uuid,name: social.name,email:social.email), handler: TokenResponse())
    }
    
    func link(social: RegisterType) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMap({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .method(.post)
                    .setPathUrl(path: "user/link_social_acc")
                switch social {
                case .facebook(let profile, _):
                    service.with(parameters: ["socialID": profile.id, "socialName": profile.name, "socialType": 1])
                    break
                case .google(let profile, _):
                    service.with(parameters: ["socialID": profile.id, "socialName": profile.name, "socialType": 2])
                    break
                case .twitter(let profile, _):
                    service.with(parameters: ["socialID": profile.id, "socialName": profile.name, "socialType": 3])
                    break
                default:
                    break
                }
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> () in
                print(json)
                return ()
            })
    }
    
    func unlink(social: SocialType) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMap({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .method(.post)
                    .setPathUrl(path: "user/unlink_social_acc")
                    .with(parameters: ["socialType": social.rawValue])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> () in
                print(json)
                return ()
            })
    }
    
    func sendResetPassword(to email: String) -> Observable<(String, SocialProfile?)> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "user/request_reset_password")
                    .method(.post)
                    .with(parameters: ["email": email])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> (String, SocialProfile?) in
                let data = json["data"]
                var profile: SocialProfile?
                if let socialType = data["socialType"].int, socialType > 0 && socialType <= 3 {
                    profile = SocialProfile()
                    profile?.id = data["socialId"].string ?? ""
                    profile?.name = data["socialName"].string ?? ""
                    profile?.type = SocialType(rawValue: socialType) ?? .facebook
                }
                return (data["tokenResetPassword"].string ?? "", profile)
            })
    }
    
    func verify(code: String, tokenResetPassword: String) -> Observable<String> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "user/verify_reset_token")
                    .method(.post)
                    .with(parameters: ["code": code, "tokenResetPassword": tokenResetPassword])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> String in
                return json["data"]["tokenVerify"].string ?? ""
            })
    }
    
    func changePassword(new password: String, token: String, uuid: String) -> Observable<(String, String?)> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "user/reset_password")
                    .method(.post)
                    .with(parameters: ["newPassword": password, "tokenVerify": token, "uuid": uuid])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> (String, String?) in
                return (json["data"]["loginToken"].string ?? "", json["data"]["firebasePassword"].string)
            })
    }
    
    func privateInfo() -> Observable<UserPrivate> {
        return self.searchDispatcher.fetch(request: PrivateUserInfoRequest(), handler: PrivateUserInfoResponse())
    }
    
    func privateInfo(with token: String) -> Observable<UserPrivate> {
        return self.searchDispatcher.fetch(request: PrivateUserInfoRequest.init(token: token), handler: PrivateUserInfoResponse())
    }
    
    func updateInfo(user: UserPrivate) -> Observable<()> {
        return self.searchDispatcher.fetch(request: UpdateUserInfoRequest(user: user), handler: UpdateUserInfoReponse())
    }
    
    func publicInfoByUserName(user:Profile) -> Observable<UserPublic> {
        return self.searchDispatcher.fetch(request: UserInfoByUsernameRequest(user: user), handler: UserInfoUsernameResponse())
    }
    
    func publicInfo(user: Profile) -> Observable<UserPublic> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "users/public/\(user.id)/info")
                    .method(.get)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> UserPublic in
                let data = json["data"]
                let userPublic = UserPublic()
                userPublic.profile.id = data["userId"].int ?? 0
                userPublic.profile.name = data["name"].string ?? ""
                userPublic.profile.username = data["username"].string ?? ""
                userPublic.profile.imageId = data["imageId"].string ?? ""
                userPublic.profile.address = data["address"].string ?? ""
                userPublic.profile.userTypeFlag = UserType(rawValue: data["userTypeFlag"].int ?? 1) ?? .normal
                userPublic.profile.about = data["about"].string ?? ""
                userPublic.reviewCount = data["reviewCount"].int ?? 0
                userPublic.sharingCount = data["sharingCount"].int ?? 0
                userPublic.followMe = data["followMe"].bool ?? false
                userPublic.followedByMe = data["followedByMe"].bool ?? false
                userPublic.articleCount = data["articleCount"].int ?? 0
                return userPublic
            })
    }
    
    func add(email: String, andPassword password: String) -> Observable<String> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMap({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "user/add_email_pass")
                    .method(.post)
                    .with(parameters: ["email": email, "password": password])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> String in
                print(json)
                return json["data"]["firebasePassword"].string ?? ""
            })
    }
    
    func update(newPassword: String, currentPassword: String, uuid: String) -> Observable<(String, String?)> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMap({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "user/change_password")
                    .method(.post)
                    .with(parameters: ["oldPassword": currentPassword, "newPassword": newPassword, "uuid": uuid])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> (String, String?) in
                print(json)
                return (json["data"]["loginToken"].string ?? "", json["data"]["firebasePassword"].string)
            })
    }
    
    func logout(uuid: String) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMap({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "user/sign_out")
                    .method(.post)
                    .with(parameters: ["uuid": uuid])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> () in
                return ()
            })
    }
    
}

//MARK: - PRIVATE USER INFO
struct PrivateUserInfoRequest:APIRequest {
    var path: String {return "user/self/info"}
    
    var headers: HTTPHeaders? {
        var params: [String: String] = [
            "Accept-Language": "Accept-Language".localized()
        ]
        if token.isEmpty {
            params["Authorization"] = "Bearer " + (Session.shared.accessToken ?? "")
        } else {
            params["Authorization"] = "Bearer \(token)"
        }
        return params
    }
    
    let token: String
    init(token: String = "") {
        self.token = token
    }
}

struct PrivateUserInfoResponse:APIResponse {
    typealias Resource = UserPrivate
    
    func map(data: Data?, statusCode: Int) -> UserPrivate? {
        guard let data = self.json(from: data, statusCode: statusCode)?["data"] else { return nil }
        print(data)
        let user = UserPrivate()
        user.parse(json: data)
        return user
    }
}


//MARK: - UPDATE USER INFO
struct UpdateUserInfoRequest:APIRequest {
    var path: String { return "user/self/info" }
    
    var method: HTTPMethod { return .patch}
    
    var headers: HTTPHeaders? {
        var params: [String: String] = [:]
        params["Accept-Language"] = "Accept-Language".localized()
        params["Authorization"] = "Bearer " + (Session.shared.accessToken ?? "")
        return params
    }
    
    var parameters: Parameters? {
        var params: [String: Any] = [:]
        if let name = user.profile?.name, !name.isEmpty {
            params["name"] = name
        }
        if let username = user.profile?.username, !username.isEmpty {
            params["username"] = username
        }
        if let about = user.profile?.about {
            params["about"] = about
        }
        if !user.interestCategory.isEmpty {
            params["interestedCategories"] = user.interestCategory.map { $0.id }
        }
        if let imageBase64 = user.profile?.imageId, !imageBase64.isEmpty {
            params["imageBase64"] = imageBase64
        }
        if let coverImageBase64 = user.profile?.coverImageId, !coverImageBase64.isEmpty {
            params["coverImageBase64"] = coverImageBase64
        }
        
        if let address = user.profile?.address, !address.isEmpty, let latitude = user.profile?.location.latitude, let longitude = user.profile?.location.longitude, (!latitude.isZero || !longitude.isZero) {
            params["address"] = address
            params["latitude"] = latitude
            params["longitude"] = longitude
        }
        return params
    }
    
    var encoding: ParameterEncoding {return JSONEncoding.default}
    
    let user:UserPrivate
}

struct UpdateUserInfoReponse:APIResponse {
    func map(data: Data?, statusCode: Int) -> ()? {
        guard let json = self.json(from: data, statusCode: statusCode)  else { return nil }
        print(json)
        return ()
    }
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}


//MARK: - USER INFO BY USERNAME
struct UserInfoByUsernameRequest:APIRequest{
    var path: String {return "user/\(user.username)"}
    
    var headers: HTTPHeaders? {
        var params: [String: String] = ["Accept-Language": "Accept-Language".localized()]
        params["Authorization"] = "Bearer " + (Session.shared.accessToken ?? "")
        return params
    }
    
    
    let user:Profile
}

struct UserInfoUsernameResponse:APIResponse{
    typealias Resource = UserPublic
    
    func map(data:Data?, statusCode: Int) -> UserPublic? {
        guard let data = self.json(from: data, statusCode: statusCode)?["data"] else { return nil }
        let userPublic = UserPublic()
        userPublic.profile.id = data["userId"].int ?? 0
        userPublic.profile.username = data["username"].string ?? ""
        userPublic.profile.name = data["name"].string ?? ""
        userPublic.profile.imageId = data["imageId"].string ?? ""
        userPublic.profile.address = data["address"].string ?? ""
        userPublic.profile.userTypeFlag = UserType(rawValue: data["userTypeFlag"].int ?? 1) ?? .normal
        userPublic.profile.about = data["about"].string ?? ""
        userPublic.reviewCount = data["reviewCount"].int ?? 0
        userPublic.sharingCount = data["instanceRelation"]["sharingCount"].int ?? 0
        userPublic.followMe = data["followRelation"]["following"].bool ?? false
        userPublic.followedByMe = data["followRelation"]["followed"].bool ?? false
        userPublic.followingCount = data["followRelation"]["followingCount"].int ?? 0
        userPublic.articleCount = data["articleRelation"]["articleCount"].int ?? 0
        return userPublic
    }
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
