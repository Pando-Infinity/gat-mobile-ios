//
//  PostCategory.swift
//  gat
//
//  Created by jujien on 9/3/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct PostCategoryRequest: APIRequest {
    var path: String { "articles/categories" }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["pageNum": self.pageNum, "pageSize": self.pageSize]
        if !self.title.isEmpty {
            params["title"] = self.title
        }
        return params
        
    }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    let title: String
    let pageNum: Int
    let pageSize: Int
    
}

struct PostCategoryResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> [PostCategory]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"].array?.compactMap({ (item) -> PostCategory? in
            guard let categoryId = item["categoryId"].int, let title = item["title"].string else { return nil }
            return PostCategory(categoryId: categoryId, title: title)
        }) ?? []
    }
}
