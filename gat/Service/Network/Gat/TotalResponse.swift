//
//  TotalResponse.swift
//  gat
//
//  Created by Vũ Kiên on 05/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON

class TotalResponse: APIResponse {
    typealias Resource = Int
    
    func map(data: Data?, statusCode: Int) -> Int? {
        return self.json(from: data, statusCode: statusCode)?["data"]["total"].int
    }
}

class TotalBookmarkResponse: APIResponse {
    typealias Resource = Int
    
    func map(data: Data?, statusCode: Int) -> Int? {
        return self.json(from: data, statusCode: statusCode)?["data"].int
    }
}
