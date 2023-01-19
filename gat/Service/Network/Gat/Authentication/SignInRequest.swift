//
//  SignInRequest.swift
//  gat
//
//  Created by jujien on 5/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// MARK: - Request
// Usernamepassword
protocol UsernamePasswordRequest: APIRequest {
    var email: String { get }
    
    var password: String { get }
    
    var uuid: String { get }
    
}

extension UsernamePasswordRequest {
    var method: HTTPMethod { .post }
    
    var parameters: Parameters? { ["email": self.email, "password": self.password, "uuid": self.uuid, "name":self.email.components(separatedBy: "@").first ?? ""] }
}

struct UsernamePasswordSignInRequest: UsernamePasswordRequest {
    var path: String { "user/login_by_email" }
    
    var email: String
    
    var password: String
    
    var uuid: String
}

struct UsernamePasswordSignUpRequest: UsernamePasswordRequest {
    
    var path: String { "user/register_by_email" }
    
    var email: String
    
    var password: String
    
    var uuid: String
    
}

// Social
struct SocialSignInRequest: APIRequest {
    var path: String { "user/login_by_social" }
    
    var method: HTTPMethod { .post }
    
    var parameters: Parameters? { ["socialID": self.socialID, "socialType": self.socialType, "uuid": self.uuid] }
    
    let socialID: String
    let socialType: Int
    let uuid: String
    
    init(socialID: String, socialType: Int, uuid: String) {
        self.socialID = socialID
        self.socialType = socialType
        self.uuid = uuid
    }
}

// Apple
struct AppleSignInRequest: APIRequest {
    var path: String { "user/login_by_social" }
    
    var method: HTTPMethod { .post }
    
    var parameters: Parameters? { ["socialID": self.socialID, "socialType": self.socialType, "uuid": self.uuid, "name":self.name, "email":self.email] }
    
    var encoding: ParameterEncoding {return JSONEncoding.default}
    
    let name:String
    let email:String
    let socialID: String
    let socialType: Int
    let uuid: String
    
    init(socialID: String, socialType: Int, uuid: String,name:String,email:String) {
        self.socialID = socialID
        self.socialType = socialType
        self.uuid = uuid
        self.name = name
        self.email = email
    }
}

struct SocialSignUpRequest: APIRequest {
    var path: String { "user/register_by_social" }
    
    var method: HTTPMethod { .post }
    
    var parameters: Parameters? { ["socialID": self.profile.id, "Image": profile.image?.toBase64() ?? "", "socialType": self.profile.type.rawValue, "name": self.profile.name, "email": self.profile.email, "password": self.password, "uuid": self.uuid] }
    
    var profile: SocialProfile
    
    var password: String
    
    var uuid: String 
}

// MARK: - Response
struct DataTokenResponse: Decodable {
    let token: String
    let userType: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        self.token = try container.decode(String.self, forKey: .token)
        self.userType = (try? container.decode(Int.self, forKey: .userType)) ?? 1
    }
}

extension DataTokenResponse {
    fileprivate enum Key: String, CodingKey {
        case token = "loginToken"
        case userType = "userTypeFlag"
    }
}

fileprivate struct DataResponse: Decodable {
    let data: DataTokenResponse
}

struct TokenResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> DataTokenResponse? {
        guard let data = data, statusCode >= 200 && statusCode < 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print("TOKEN JSON RESPONSE: \(json)")
        let jsonDecoder = JSONDecoder()
        return try? jsonDecoder.decode(DataResponse.self, from: data).data
    }
}
