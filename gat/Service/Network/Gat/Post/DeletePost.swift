//
//  DeletePost.swift
//  gat
//
//  Created by jujien on 9/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct DeletePostRequest: APIRequest {
    var path: String { "articles/\(self.id)" }
    
    var method: HTTPMethod { .delete }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    let id: Int
}

struct DeletePostResponse: APIResponse {
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
