//
//  ListAllArticles.swift
//  gat
//
//  Created by macOS on 10/22/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct ListAllArticleResquest: APIRequest {
    var path: String {return "articles"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
    
}

struct ListNewPostReviewRequest:APIRequest {
    var path: String {return "articles"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["categoryIds":[0].map { "\($0)" }.joined(separator: ","),"pageNum": self.pageNum,"pageSize": self.pageSize] //review
    }
    
    var pageNum:Int
    
    var pageSize:Int
}

struct ListCatergoryArticleResquest: APIRequest {
    var path: String {return "articles"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["categoryIds":self.catergory.map { "\($0)" }.joined(separator: ","),"pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
    
    var catergory:[Int]
    
}

struct ListHashtagArticleResquest: APIRequest {
    var path: String {return "articles"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["hashtagIds":self.hashtag.map { "\($0)" }.joined(separator: ","),"pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
    
    var hashtag:[Int]
    
}

struct ListSavedArticleResquest: APIRequest {
    var path: String {return "articles/bookmarks"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
    
}

struct ListDraftArticleResquest: APIRequest {
    var path: String {return "articles/self"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["states":[0].map { "\($0)" }.joined(separator: ","),"pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
    
}

struct ListSelfArticleResquest: APIRequest {
    var path: String {return "articles/self"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
    
}

struct ListArticleUserRequest: APIRequest {
    var path: String {return "articles"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["creatorId":self.userId,"title": self.title ,"pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
    
    var userId:Int
    
    var title:String = ""
    
}

struct TrendingPostRequest:APIRequest {
    var path: String {return "articles?&sorts=reactCount,DESC"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["categoryIds": [0].map { "\($0)" }.joined(separator: ","),"pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
}

struct BookStopMemberPostRequest:APIRequest{
    var path: String {return "articles/bookstop/\(self.bookstopId)"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
    
    var bookstopId:Int
}


struct BookStopPopularPostRequest:APIRequest {
    var path: String {return "articles/bookstop/\(self.bookstopId)?&sorts=reactCount,DESC"}
    
    var method: HTTPMethod {return .get}
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var parameters: Parameters?{
        return ["pageNum": self.pageNum,"pageSize": self.pageSize]
    }
    
    var pageNum:Int
    
    var pageSize:Int
    
    var bookstopId:Int
}
