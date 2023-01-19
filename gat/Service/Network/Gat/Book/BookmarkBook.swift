//
//  BookmarkBook.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class AddBookmarkBookRequest: APIRequest {
    var path: String {
        return "editions/\(self.editionId)/save"
    }
    
    var parameters: Parameters? {
        return ["value": self.value]
    }
    
    fileprivate let editionId: Int
    fileprivate let value: Bool
    
    var method: HTTPMethod {
        return .post 
    }
    
    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }
    
    init(editionId: Int, value: Bool) {
        self.editionId = editionId
        self.value = value
    }
}

