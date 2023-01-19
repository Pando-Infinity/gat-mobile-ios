//
//  GetHashtag.swift
//  gat
//
//  Created by jujien on 24/11/2020.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct GetHashtagRequest: APIRequest {
    var path: String { "hashtags" }
    
    var parameters: Parameters? { ["tagName": self.tagName, "pageNum": self.pageNum, "pageSize": self.pageSize] }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    let tagName: String
    let pageNum: Int
    let pageSize: Int
}

struct GetHashtagResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> [Hashtag]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        return json["data"]["pageData"].array?.compactMap({ (item) -> Hashtag? in
            guard let id = item["tagId"].int else { return nil }
            return .init(id: id, name: item["tagName"].string ?? "", count: item["taggedCount"].int ?? 0)
        })
    }
    
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
