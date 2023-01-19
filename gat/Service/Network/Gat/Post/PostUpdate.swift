//
//  PostUpdate.swift
//  gat
//
//  Created by jujien on 9/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct PostUpdateRequest: APIRequest {
    var path: String {
        let p = "articles"
        if self.post.id == 0 {
            return p
        } else {
            return p + "/\(self.post.id)"
        }
    }
    
    var method: HTTPMethod {
        if self.post.id == 0 {
            return .post
        } else {
            return .patch
        }
    }
    
    var parameters: Parameters? {
        [
            "body": self.post.body,
            "bodyImageIds": self.post.postImage.bodyImages,
            "categoryIds": self.post.categories.map { $0.categoryId },
            "coverId": self.post.postImage.coverImage,
            "editionIds": self.post.editionTags.map { $0.editionId },
            "intro": self.post.intro,
            "scheduledPost": self.post.date.scheduledPost?.string(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") as Any,
            "state": self.post.state.rawValue,
            "tagIds": self.post.hashtags.filter { $0.id != 0 }.map { $0.id },
            "tagNames": self.post.hashtags.map { $0.name },
            "thumbId": self.post.postImage.thumbnailId,
            "title": self.post.title,
            "userIds": self.post.userTags.map { $0.id }
        ]
    }
    
    var encoding: ParameterEncoding { JSONEncoding.default }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    let post: Post
    
    init(post: Post) {
        self.post = post
    }
}

struct PostUpdateResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> Post? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        let data = json["data"]
        guard let articleId = data["articleId"].int else { return nil }
        
        let creator = Profile()
        creator.id = data["creator"]["userId"].int ?? 0
        creator.name = data["creator"]["name"].string ?? ""
        creator.username = data["creator"]["username"].string ?? ""
        creator.about = data["creator"]["about"].string ?? ""
        creator.address = data["creator"]["address"].string ?? ""
        creator.coverImageId = data["creator"]["coverImageId"].string ?? ""
        creator.imageId = data["creator"]["imageId"].string ?? ""
        creator.userTypeFlag = UserType(rawValue: data["creator"]["userTypeFlag"].int ?? 1) ?? .normal
        creator.location = .init(latitude: data["creator"]["latitude"].double ?? 0.0, longitude: data["creator"]["longitude"].double ?? 0.0)
        
        let categories = data["categories"].array?.map { PostCategory(categoryId: $0["categoryId"].int ?? 0, title: $0["title"].string ?? "") } ?? []
        
        let image = PostImage(thumbnailId: data["thumbnailId"].string ?? "", coverImage: data["coverId"].string ?? "", bodyImages: data["bodyImageIds"].array?.compactMap { $0.string } ?? [])
        
        let editions = data["editions"].array?.compactMap({ (item) -> BookInfo? in
            guard let editionId = item["editionId"].int else { return nil }
            let book = BookInfo()
            book.editionId = editionId
            book.title = item["title"].string ?? ""
            book.author = item["title"].string ?? ""
            book.rateAvg = item["rateAvg"].double ?? 0.0
            book.imageId = item["imageId"].string ?? ""
            return book
        }) ?? []
        
        let users = data["users"].array?.compactMap({ (item) -> Profile? in
            guard let userId = item["userId"].int else { return nil }
            let profile = Profile()
            profile.id = userId
            profile.name = item["name"].string ?? ""
            profile.username = item["username"].string ?? ""
            profile.about = item["about"].string ?? ""
            profile.address = item["address"].string ?? ""
            profile.coverImageId = item["coverImageId"].string ?? ""
            profile.imageId = item["imageId"].string ?? ""
            profile.userTypeFlag = UserType(rawValue: item["userTypeFlag"].int ?? 1) ?? .normal
            profile.location = .init(latitude: item["latitude"].double ?? 0.0, longitude: item["longitude"].double ?? 0.0)
            return profile
        }) ?? []
        
        let hashtags = data["hashtags"].array?.map { Hashtag(id: $0["tagId"].int ?? 0, name: $0["tagName"].string ?? "", count: $0["taggedCount"].int ?? 0) } ?? []
        
        let date = PostDate(scheduledPost: data["scheduledPost"].string?.date(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"), lastUpdate: data["lastUpdate"].string?.date(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"), publishedDate: data["publishedDate"].string?.date(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"))
        
        let summary = PostSummary(reactCount: data["reactCount"].int ?? 0, commentCount: data["commentCount"].int ?? 0, shareCount: data["shareCount"].int ?? 0)
        let userReaction = UserReaction(reactionId: data["userRelation"]["userReaction"]["reactionId"].int ?? 0, reactCount: data["userRelation"]["userReaction"]["reactCount"].int ?? 0)
        
        var post: Post = .init(id: articleId, title: data["title"].string ?? "", intro: data["intro"].string ?? "", body: data["body"].string ?? "", creator: .init(profile: creator, isFollowing: false), categories: categories, postImage: image, editionTags: editions, userTags: users, hashtags: hashtags, state: Post.State(rawValue: data["state"].int ?? 1) ?? .draft, date: date, userReaction: userReaction, summary: summary, rating: 0.0, saving: data["saved"].bool ?? false)
        if post.isReview {
            post.rating = data["editions"].array?.first?["userRelation"]["evaluation"]["rate"].double ?? 0.0
        }
        return post
    }
    
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
