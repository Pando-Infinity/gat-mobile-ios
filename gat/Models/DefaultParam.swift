//
//  DefaultParam.swift
//  gat
//
//  Created by jujien on 9/10/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation

protocol ParamRequest {
    var pageNum: Int { get set }
    var pageSize: Int { get set }
}

struct DefaultParam: ParamRequest {
    var text: String? = nil
    var pageNum: Int
    var pageSize: Int = 10
}
