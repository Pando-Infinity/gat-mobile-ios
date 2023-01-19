//
//  ListReview.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class ListReviewBookRequest: APIRequest {
    var path: String {
        return AppConfig.sharedConfig.get("book_evaluation")
    }
    
    var parameters: Parameters? {
        return ["editionId": self.editionId, "page": self.page, "per_page": self.per_page, "reviewType": 3]
    }
    
    fileprivate let editionId: Int
    fileprivate let page: Int
    fileprivate let per_page: Int
    
    init(editionId: Int, page: Int, per_page: Int) {
        self.editionId = editionId
        self.page = page
        self.per_page = per_page
    }
}

class ListReviewBookResponse: APIResponse {
    typealias Resource = [Review]
    
    fileprivate let book: BookInfo
    
    init(book: BookInfo) {
        self.book = book
    }
    
    func map(data: Data?, statusCode: Int) -> [Review]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["resultInfo"].array?.map({ (json) -> Review in
            let review = Review()
            review.reviewId = json["evaluationId"].int ?? 0
            review.reviewType = json["reviewType"].int ?? 0
            review.intro = json["intro"].string ?? ""
            review.review = json["review"].string ?? ""
            review.evaluationTime = .init(timeIntervalSince1970: (json["evaluationTime"].double ?? 0.0) / 1000.0)
            review.value = json["value"].double ?? 0.0
            review.draftFlag = json["draftFlag"].bool ?? false
            
            review.book = self.book
            review.user?.id = json["userId"].int ?? 0
            review.user?.name = json["name"].string ?? ""
            review.user?.address = json["address"].string ?? ""
            review.user?.userTypeFlag = UserType(rawValue: json["userTypeFlag"].int ?? 0) ?? .normal
            review.user?.imageId = json["imageId"].string ?? ""
            return review
        }) ?? []
    }
}
