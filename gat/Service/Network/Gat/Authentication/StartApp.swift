//
//  StartApp.swift
//  gat
//
//  Created by macOS on 9/11/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct StartAppRequest: APIRequest{
    var path: String {"user/start_app"}
    
    var method: HTTPMethod {.post}
    
    var parameters: Parameters? {
        ["uuid" : self.uuid]
    }
    
    var uuid:String
    
}

struct StartAppResponse : APIResponse{
    typealias Resource = ()
    
    func map(data: Data?, statusCode: Int) -> ()? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print("START APP: \(json)")
        return ()
    }
}
