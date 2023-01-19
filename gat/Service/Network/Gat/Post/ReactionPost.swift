//
//  ReactionPost.swift
//  gat
//
//  Created by jujien on 9/30/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct ReactionPostRequest: APIRequest {
    var path: String { "articles/\(self.postId)/reaction" }
    
    var method: HTTPMethod { .post }
    
    var parameters: Parameters? { ["reactCount": self.reactCount, "reactionId": self.reactionId] }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    var encoding: ParameterEncoding { JSONEncoding.default }
    
    let postId: Int
    let reactCount: Int
    let reactionId: Int
}

struct ReactionPostResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> ()? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return ()
    }
    
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
    
}
