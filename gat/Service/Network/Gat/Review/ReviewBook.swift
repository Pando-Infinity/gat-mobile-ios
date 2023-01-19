//
//  ReviewBook.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class ReviewBookRequest: APIRequest {
    var path: String {
        return AppConfig.sharedConfig.get("book_user_evaluation")
    }
    
    var parameters: Parameters? {
        return ["editionId": self.editionId]
    }
    
    fileprivate let editionId: Int
    
    init(editionId: Int) {
        self.editionId = editionId
    }
}

class ReviewBookResponse: APIResponse {
    typealias Resource = Review
    
    fileprivate let book: BookInfo
    
    init(book: BookInfo) {
        self.book = book
    }
    
    func map(data: Data?, statusCode: Int) -> Review? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        let resultInfo = json["data"]["resultInfo"]
        print(json)
        let review = Review()
        review.book = self.book
        review.reviewId = resultInfo["evaluationId"].int ?? 0
        review.intro = resultInfo["intro"].string ?? ""
        review.review = resultInfo["review"].string ?? ""
        review.draftFlag = resultInfo["draftFlag"].bool ?? false
        review.reviewType = resultInfo["reviewType"].int ?? 0
        review.value = resultInfo["value"].double ?? 0.0
        if let evaluationTime = resultInfo["evaluationTime"].double {
            review.evaluationTime = Date(timeIntervalSince1970: evaluationTime / 1000.0)
        }
        return review
    }
}
