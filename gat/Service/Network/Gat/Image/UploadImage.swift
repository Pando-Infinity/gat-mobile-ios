//
//  UploadImage.swift
//  gat
//
//  Created by jujien on 8/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct UploadImageRequest: APIRequest {
    var path: String { "common/upload_image_base64" }
    
    var method: HTTPMethod { .post }
    
    var parameters: Parameters? {
        guard let data = self.base64.data(using: .utf8) else { return nil }
        return ["base64": data]
    }

    let base64: String
}

struct UserUploadImageRequest: APIRequest {
    var path: String { "user-images" }
    
    var method: HTTPMethod { .post }
    
    var parameters: Parameters? { ["imageBase64": self.base64] }
    
    var encoding: ParameterEncoding { JSONEncoding.default }
    
    var headers: HTTPHeaders? {
        [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer \(Session.shared.accessToken ?? "")"
        ]
    }
    
    let base64: String
}

struct UploadImageResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> String? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["resultInfo"].string
    }
}

struct UserUploadImageResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> String? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["imageId"].string
    }
    
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
