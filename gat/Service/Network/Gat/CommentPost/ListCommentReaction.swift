//
//  ListCommentReaction.swift
//  gat
//
//  Created by jujien on 11/6/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct ListReactionCommentPostRequest: APIRequest {
    var path: String { "articles/comments/\(self.commentId)/reaction" }
    
    var parameters: Parameters? { ["pageNum": self.pageNum, "pageSize": self.pageSize] }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    let commentId: Int
    var pageNum: Int
    var pageSize: Int
    
}

struct ListReactionCommentPostResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> ([UserReactionInfo], Int)? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        return (json["data"]["pageData"].array?.compactMap({ (item) -> UserReactionInfo? in
            let userItem = item["user"]
            guard let id = userItem["userId"].int else { return nil }
            let userReaction = UserReaction(reactionId: item["reactionId"].int ?? 0, reactCount: item["reactCount"].int ?? 0)
            let user = Profile()
            user.id = id
            user.about = userItem["about"].string ?? ""
            user.address = userItem["address"].string ?? ""
            user.coverImageId = userItem["coverImageId"].string ?? ""
            user.imageId = userItem["imageId"].string ?? ""
            user.name = userItem["name"].string ?? ""
            user.username = userItem["username"].string ?? ""
            user.userTypeFlag = UserType(rawValue: userItem["userTypeFlag"].int ?? 1) ?? .normal
            user.location = .init(latitude: userItem["latitude"].double ?? 0, longitude: userItem["longitude"].double ?? 0)
            return .init(userReaction: userReaction, profile: user)
        }) ?? [], json["data"]["total"].int ?? 0)
    }
    
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
