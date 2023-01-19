//
//  SearchUser.swift
//  gat
//
//  Created by jujien on 11/16/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

struct SearchUserRequest: APIRequest {
    var path: String { return "user/search" }
    
    var method: HTTPMethod { return .put }
    
    var headers: HTTPHeaders? {
        return [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer " + (Session.shared.accessToken ?? "")
        ]
    }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["pageNum": self.page, "pageSize": self.perPage]
        var criteria: [String: Any] = [:]
        if let location = self.location {
            criteria["currentLatitude"] = location.latitude
            criteria["currentLongitude"] = location.longitude
        }
        switch self.type {
        case .all:
            criteria["nameOrUsername"] = self.keyword
        case .name:
            criteria["name"] = self.keyword
        case .email:
            criteria["email"] = self.keyword
        case .username:
            criteria["username"] = self.keyword
        }
        params["criteria"] = criteria
        return params
    }
    
    var encoding: ParameterEncoding { return JSONEncoding.default }
    
    let type: SearchUserType = .all
    
    let keyword: String
    
    let location: CLLocationCoordinate2D?
    
    let page: Int
    
    let perPage: Int
}

extension SearchUserRequest {
    enum SearchUserType: String {
        case all = "ALL"
        case name = "NAME"
        case email = "EMAIL"
        case username = "USERNAME"
    }
}

struct SearchUserResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> ([UserPublic], Int)? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        let users = json["data"]["pageData"].array?.compactMap({ (item) -> UserPublic? in
            let user = UserPublic()
            user.profile.id = item["userId"].int ?? 0
            user.profile.name = item["name"].string ?? ""
            user.profile.imageId = item["imageId"].string ?? ""
            user.profile.address = item["address"].string ?? ""
            user.profile.about = item["about"].string ?? ""
            user.sharingCount = item["summary"]["sharingCount"].int ?? 0
            user.reviewCount = item["summary"]["reviewCount"].int ?? 0
            user.profile.userTypeFlag = UserType(rawValue: item["userTypeFlag"].int ?? 1) ?? .normal
            user.distance = item["distanceToCurrentUser"].double ?? 0.0
            user.profile.location = .init(latitude: item["latitude"].double ?? 0.0, longitude: item["longitude"].double ?? 0.0)
            return user 
        }) ?? []
        let total = json["data"]["total"].int ?? 0
        return (users, total)
    }
}
