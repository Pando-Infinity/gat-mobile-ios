//
//  File.swift
//  gat
//
//  Created by Vũ Kiên on 05/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class SharingBookUserRequest: APIRequest {
    var path: String { return "" }
    
    var method: HTTPMethod { return .post }
    
    var encoding: ParameterEncoding { return JSONEncoding.default }
    
    var parameters: Parameters? { return nil }
    
    fileprivate let page: Int
    fileprivate let perpage: Int
    fileprivate let keyword: String?
    
    init(keyword: String?, page: Int, perpage: Int ) {
        self.page = page
        self.perpage = perpage
        self.keyword = keyword
    }
    
    var params: Parameters {
        var dict: [String: Any] = ["page": self.page, "perPage": self.perpage]
        if let keyword = self.keyword, !keyword.isEmpty {
            dict["keyWord"] = keyword
        }
        return dict
    }
    
}
