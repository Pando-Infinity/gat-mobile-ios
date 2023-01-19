//
//  ListNewReview.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class ListNewReviewRequest: APIRequest {
    var path: String {
        return "reviews/new_long_reviews"
    }
    
    var parameters: Parameters? {
        return ["page": self.page, "per_page": self.per_page]
    }
    
    fileprivate let page: Int
    fileprivate let per_page: Int
    
    init(page: Int, per_page: Int) {
        self.page = page
        self.per_page = per_page
    }
}

class ListNewReviewResponse: APIResponse {
    typealias Resource = [Review]
    
    func map(data: Data?, statusCode: Int) -> [Review]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"].array?.map({ (json) -> Review in
            let review  = Review()
            review.reviewId = json["evaluation"]["reviewId"].int ?? 0
            review.intro = json["evaluation"]["intro"].string ?? ""
            review.reviewType = json["evaluation"]["reviewType"].int ?? 0
            review.value = json["evaluation"]["value"].double ?? 0.0
            review.draftFlag = json["evaluation"]["draftFlag"].bool ?? false
            review.saving = json["saving"]["saving"].bool ?? false
            review.review = json["evaluation"]["review"].string ?? ""
            review.evaluationTime = Date(timeIntervalSince1970: TimeInterval((json["evaluation"]["evaluationTime"].int64 ?? 0) / 1000))
            
            review.book?.editionId = json["edition"]["editionId"].int ?? 0
            review.book?.title = json["edition"]["title"].string ?? ""
            review.book?.imageId = json["edition"]["imageId"].string ?? ""
            review.book?.author = json["edition"]["author"].string ?? ""
            review.book?.rateAvg = json["edition"]["rateAvg"].double ?? 0.0
            
            review.user?.id = json["userInfo"]["userId"].int ?? 0
            review.user?.name = json["userInfo"]["name"].string ?? ""
            review.user?.address = json["userInfo"]["address"].string ?? ""
            review.user?.userTypeFlag = UserType(rawValue: json["userTypeFlag"].int ?? 0) ?? .normal
            review.user?.imageId = json["userInfo"]["imageId"].string ?? ""
            review.user?.about = json["userInfo"]["about"].string ?? ""
            return review
        }) ?? []
    }
}
