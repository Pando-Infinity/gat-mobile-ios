//
//  APIResponse.swift
//  gat
//
//  Created by Vũ Kiên on 02/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol APIResponse {
    associatedtype Resource: Any
    
    func map(data: Data?, statusCode: Int) -> Self.Resource?
    
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError?
}

extension APIResponse {
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": json["message"].string ?? ""])
    }
    
    func json(from data: Data?, statusCode: Int) -> JSON? {
        guard let data = data, statusCode >= 200 && statusCode < 400 else { return nil }
        return try? JSON(data: data)
    }
}
