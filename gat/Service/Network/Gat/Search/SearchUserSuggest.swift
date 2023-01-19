//
//  SearchUserSuggest.swift
//  gat
//
//  Created by jujien on 11/16/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

struct SearchUserSuggestionRequest: APIRequest {
    var path: String { return "user/suggestion" }
    
    var parameters: Parameters? {
        return ["size": self.size, "type": self.type.rawValue, "keyword": self.keyword]
    }
    
    var headers: HTTPHeaders? {
        return [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer " + (Session.shared.accessToken ?? "")
        ]
    }
    
    let keyword: String
    
    let type: SearchUserType = .all
    
    let size: Int
}

extension SearchUserSuggestionRequest {
    enum SearchUserType: String {
        case all = "ALL"
        case name = "NAME"
        case email = "EMAIL"
        case username = "USERNAME"
    }
}

struct SearchUserSuggestionResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> [UserPublic]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print("JSON:\(json)")
        return json["data"].array?.compactMap({ (item) -> UserPublic? in
            let userPublic = UserPublic()
            userPublic.profile.id = item["userId"].int ?? 0
            userPublic.profile.name = item["name"].string ?? ""
            userPublic.profile.imageId = item["imageId"].string ?? ""
            userPublic.profile.address = item["address"].string ?? ""
            userPublic.profile.about = item["about"].string ?? ""
            userPublic.profile.userTypeFlag = UserType(rawValue: item["userTypeFlag"].int ?? 1) ?? .normal
            return userPublic
        })
    }
}
