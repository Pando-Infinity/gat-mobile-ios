//
//  ReviewRequest.swift
//  gat
//
//  Created by Vũ Kiên on 09/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct ReviewRequest: APIRequest {
    var path: String {
        return "reviews/\(self.reviewId)/info"
    }
    
    fileprivate let reviewId: Int
    
    init(reviewId: Int) {
        self.reviewId = reviewId
    }
}

struct ReviewResponse: APIResponse {
    typealias Resource = Review
    
    func map(data: Data?, statusCode: Int) -> Review? {
        guard let data = self.json(from: data, statusCode: statusCode)?["data"] else { return nil }
        print(data)
        let review = Review()
        review.reviewId = data["evaluation"]["reviewId"].int ?? 0
        review.user?.id = data["userInfo"]["userId"].int ?? 0
        review.user?.name = data["userInfo"]["name"].string ?? ""
        review.user?.imageId = data["userInfo"]["imageId"].string ?? ""
        review.user?.address = data["userInfo"]["address"].string ?? ""
        review.user?.userTypeFlag = UserType(rawValue: data["userInfo"]["userTypeFlag"].int ?? 1) ?? .normal
        review.user?.about = data["userInfo"]["about"].string ?? ""
        review.book?.editionId = data["edition"]["editionId"].int ?? 0
        review.book?.bookId = data["edition"]["bookId"].int ?? 0
        review.book?.title = data["edition"]["title"].string ?? ""
        review.book?.author = data["edition"]["review"].string ?? ""
        review.book?.imageId = data["edition"]["imageId"].string ?? ""
        review.reviewType = data["evaluation"]["reviewType"].int ?? 1
        review.intro = data["evaluation"]["intro"].string ?? ""
        review.value = data["evaluation"]["value"].double ?? 0.0
        review.review = data["evaluation"]["review"].string ?? ""
        review.draftFlag = data["evaluation"]["draftFlag"].bool ?? false
        review.evaluationTime = .init(timeIntervalSince1970: (data["evaluation"]["evaluationTime"].double ?? 0.0) / 1000.0)
        review.saving = data["saving"]["saving"].bool ?? false 
        return review
    }
}
