//
//  CreateCommentPost.swift
//  gat
//
//  Created by jujien on 9/9/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct CreateCommentPostRequest: APIRequest {
    var path: String {
        if self.comment.id == 0 {
            return "articles/\(self.comment.post.id)/comments"
        } else {
            return "articles/comments/\(self.comment.id)"
        }
    }
    
    var method: HTTPMethod {
        if self.comment.id == 0 {
            return .post
        } else {
            return .patch
        }
    }
    
    var parameters: Parameters? { ["content": self.comment.content, "editionIds": self.comment.editionTags.map { $0.editionId }, "userIds": self.comment.usersTags.map { $0.id }] }
    
    var encoding: ParameterEncoding { JSONEncoding.default }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    let comment: CommentPost
}


struct CreateCommentPostResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> CommentPost? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        let item = json["data"]
        guard let commentId = item["commentId"].int/*, let articleId = item["articleId"].int*/ else { return nil }
        let post = Post(id: item["articleId"].int ?? 0, title: "", intro: "", body: "", creator: .init(profile: .init(), isFollowing: false))
        let commentToEditions = item["commentToEditions"].array?.compactMap({ (i) -> BookInfo? in
            guard let editionId = i["editionId"].int else { return nil }
            let book = BookInfo()
            book.editionId = editionId
            book.title = i["title"].string ?? ""
            book.author = i["authorName"].string ?? ""
            book.rateAvg = i["rateAvg"].double ?? 0.0
            book.imageId = i["imageId"].string ?? ""
            return book
        }) ?? []
        let commentToUsers = item["commentToUsers"].array?.compactMap({ (i) -> Profile? in
            guard let userId = i["userId"].int else { return nil }
            let user = Profile()
            user.id = userId
            user.username = i["username"].string ?? ""
            user.userTypeFlag = UserType(rawValue: i["userTypeFlag"].int ?? 1) ?? .normal
            user.name = i["name"].string ?? ""
            user.about = i["about"].string ?? ""
            user.address = i["address"].string ?? ""
            user.imageId = i["imageId"].string ?? ""
            user.coverImageId = i["coverImageId"].string ?? ""
            user.location = .init(latitude: i["latitude"].double ?? 0.0, longitude: i["longitude"].double ?? 0.0)
            return user
        }) ?? []
        let user = Profile()
        user.id = item["user"]["userId"].int ?? 0
        user.username = item["user"]["username"].string ?? ""
        user.userTypeFlag = UserType(rawValue: item["user"]["userTypeFlag"].int ?? 1) ?? .normal
        user.name = item["user"]["name"].string ?? ""
        user.about = item["user"]["about"].string ?? ""
        user.address = item["user"]["address"].string ?? ""
        user.imageId = item["user"]["imageId"].string ?? ""
        user.coverImageId = item["user"]["coverImageId"].string ?? ""
        user.location = .init(latitude: item["user"]["latitude"].double ?? 0.0, longitude: item["user"]["longitude"].double ?? 0.0)
        
        return CommentPost(id: commentId, post: post, editionTags: commentToEditions, usersTags: commentToUsers, content: item["content"].string ?? "", user: user, lastUpdate: item["lastUpdate"].string?.date(format: "yyyy-MM-dd'T'HH:mm:ss.SSZ") ?? Date(), summary: .init(reactCount: item["reactCount"].int ?? 0, replyCount: item["replyCount"].int ?? 0))
    }
    
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
