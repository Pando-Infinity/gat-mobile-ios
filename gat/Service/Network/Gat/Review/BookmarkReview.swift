//
//  BookmarkReview.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class BookmarkReviewRequest: APIRequest {
    var path: String {
        return "reviews/\(self.reviewId)/save"
    }
    
    var parameters: Parameters? { return ["value": self.value] }
    
    var method: HTTPMethod { return .post }
    
    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }
    
    fileprivate let reviewId: Int
    fileprivate let value: Bool
    
    init(reviewId: Int, value: Bool) {
        self.reviewId = reviewId
        self.value = value
    }
}
