//
//  PostSaving.swift
//  gat
//
//  Created by jujien on 10/22/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

struct PostSavingRequest: APIRequest {
    var path: String { "articles/\(self.id)/bookmarks" }
    
    var method: HTTPMethod { .post }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    let id: Int
    let saving: Bool
}

struct PostSavingResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> ()? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
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
