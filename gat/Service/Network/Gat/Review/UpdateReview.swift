//
//  UpdateReview.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class UpdateReviewRequest: APIRequest {
    var path: String {
        return AppConfig.sharedConfig.get("update_book_evaluation")
    }
    
    var parameters: Parameters? {
        var params: Parameters = ["editionId": self.review.book!.editionId, "bookId": self.review.book!.bookId, "value": self.review.value, "reviewType": self.review.reviewType, "draftFlag": self.review.draftFlag]
        params["readingId"] = 0
        if !self.review.review.isEmpty {
            params["review"] = self.review.review
        }
        if !self.review.intro.isEmpty {
            params["Intro"] = self.review.intro
        }
        return params
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    fileprivate let review: Review
    
    init(review: Review) {
        self.review = review
    }
}

class UpdateReviewResponse: APIResponse {
    typealias Resource = (Review, Double)
    
    fileprivate let review: Review
    
    init(review: Review) {
        self.review = review
    }
    
    func map(data: Data?, statusCode: Int) -> (Review, Double)? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        let data = json["data"]
        if let evaluationId = data["evaluationId"].int {
            self.review.reviewId = evaluationId
        }
        return (review, data["newAvgRate"].double ?? 0.0)
    }
}
