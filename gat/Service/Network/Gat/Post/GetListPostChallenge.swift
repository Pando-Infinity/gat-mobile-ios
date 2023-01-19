//
//  GetListPostChallenge.swift
//  gat
//
//  Created by macOS on 10/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct GetListPostChallengeRequest: APIRequest {
    var path: String { "articles/challenge/\(self.challenge.id)" }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters? {
        [
            "pageNum": self.pageNum,
            "pageSize" : self.pageSize
        ]
    }
    
    var method: HTTPMethod {.get}
    
    var challenge: Challenge
    var pageNum:Int
    var pageSize:Int
}

class TotalSavedPostResponse: APIResponse {
    typealias Resource = Int
    
    func map(data: Data?, statusCode: Int) -> Int? {
        return self.json(from: data, statusCode: statusCode)?["data"]["total"].int
    }
}

struct GetListPostChallengeResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> [Post]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        var listPost:[Post] = []
        let data = json["data"]["pageData"]
        if data != JSON.null {
            for postElement in data.array ?? [] {
                guard let articleId = postElement["articleId"].int else { return nil }
                let title = postElement["title"].string ?? ""
                let intro = postElement["intro"].string ?? ""
                let creator = Profile()
                creator.id = postElement["creator"]["userId"].int ?? 0
                creator.name = postElement["creator"]["name"].string ?? ""
                creator.username = postElement["creator"]["username"].string ?? ""
                creator.about = postElement["creator"]["about"].string ?? ""
                creator.address = postElement["creator"]["address"].string ?? ""
                creator.coverImageId = postElement["creator"]["coverImageId"].string ?? ""
                creator.imageId = postElement["creator"]["imageId"].string ?? ""
                creator.userTypeFlag = UserType(rawValue: postElement["creator"]["userTypeFlag"].int ?? 1) ?? .normal
                creator.location = .init(latitude: postElement["creator"]["latitude"].double ?? 0.0, longitude: postElement["creator"]["longitude"].double ?? 0.0)
                
                let categories = postElement["categories"].array?.map { PostCategory(categoryId: $0["categoryId"].int ?? 0, title: $0["title"].string ?? "") } ?? []
                
                let image = PostImage(thumbnailId: postElement["thumbnailId"].string ?? "", coverImage: postElement["coverId"].string ?? "", bodyImages: postElement["bodyImageIds"].array?.compactMap { $0.string } ?? [])
                
                let editions = postElement["editions"].array?.compactMap({ (item) -> BookInfo? in
                    guard let editionId = item["editionId"].int else { return nil }
                    let book = BookInfo()
                    book.editionId = editionId
                    book.title = item["title"].string ?? ""
                    book.author = item["authorName"].string ?? ""
                    book.rateAvg = item["rateAvg"].double ?? 0.0
                    book.imageId = item["imageId"].string ?? ""
                    return book
                }) ?? []
                
                let users = postElement["users"].array?.compactMap({ (item) -> Profile? in
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
                
                let hashtags = postElement["hashtags"].array?.map { Hashtag(id: $0["tagId"].int ?? 0, name: $0["tagName"].string ?? "", count: $0["taggedCount"].int ?? 0) } ?? []
                
                let date = PostDate(scheduledPost: postElement["scheduledPost"].string?.date(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"), lastUpdate: postElement["lastUpdate"].string?.date(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"), publishedDate: postElement["publishedDate"].string?.date(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"))
                
                let userReaction = postElement["userRelation"]["userReaction"]
                let reactId = userReaction["reactionId"].int ?? 0
                let reactCount = userReaction["reactCount"].int ?? 0
                let userReact = UserReaction(reactionId: reactId, reactCount: reactCount)
                
                let summary = PostSummary(reactCount: postElement["reactCount"].int ?? 0, commentCount: postElement["commentCount"].int ?? 0, shareCount: postElement["shareCount"].int ?? 0)
                
                var post: Post = .init(id: articleId, title: title, intro: intro, body: postElement["body"].string ?? "", creator: .init(profile: creator, isFollowing: false), categories: categories, postImage: image, editionTags: editions, userTags: users, hashtags: hashtags, state: Post.State(rawValue: postElement["state"].int ?? 1) ?? .draft, date: date, userReaction: userReact, summary: summary, rating: 0.0, saving: postElement["saved"].bool ?? false)
                if post.isReview {
                    post.rating = postElement["editions"].array?.first?["userRelation"]["evaluation"]["rate"].double ?? 0.0
                }
                listPost.append(post)
            }
        }
        return listPost
    }
    
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
