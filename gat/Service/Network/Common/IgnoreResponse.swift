//
//  IgnoreResponse.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation

class IgnoreResponse: APIResponse {
    typealias Resource = ()
    
    func map(data: Data?, statusCode: Int) -> ()? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        return ()
    }
}
