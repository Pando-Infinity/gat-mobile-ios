//
//  RemoveReview.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class RemoveReviewRequest: APIRequest {
    var path: String {
        return "book/self_remove_review"
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        return ["evaluationId": self.evaluationId]
    }
    
    
    
    fileprivate let evaluationId: Int
    
    init(evaluationId: Int) {
        self.evaluationId = evaluationId
    }
}
