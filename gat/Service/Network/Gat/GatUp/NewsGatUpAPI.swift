//
//  NewsGatUpAPI.swift
//  gat
//
//  Created by jujien on 12/31/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct NewsGatupRequest: APIRequest {
    var path: String { return "gat_up/news" }
    
    var parameters: Parameters? { return ["pageNum": self.page, "pageSize": self.per_page] }
    
    let page: Int
    let per_page: Int
}

struct NewsGatupResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> [NewsBookstop]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"].array?.map { NewsBookstop(json: $0) }
    }
}
