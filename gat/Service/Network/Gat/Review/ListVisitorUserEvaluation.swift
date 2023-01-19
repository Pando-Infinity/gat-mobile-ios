//
//  ListVisitorUserEvaluation.swift
//  gat
//
//  Created by Vũ Kiên on 05/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class ListVisitorUserEvaluationRequest: ListEvaluationRequest {
    override var path: String {
        return "book_v12/users/\(self.userId)/book_evaluations/search"
    }
    
    fileprivate let userId: Int
    
    init(userId: Int, keyword: String?, option: EvaluationFilterOption, page: Int, perpage: Int) {
        self.userId = userId
        super.init(keyword: keyword, option: option, page: page, perpage: perpage)
    }
}

struct ListVisitorUserEvaluationResponse: APIResponse {
    typealias Resource = [Review]
    
    func map(data: Data?, statusCode: Int) -> [Review]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"]
            .array?
            .map({ (json) -> Review in
                let review = Review()
                review.reviewId = json["reviewId"].int ?? 0
                review.book?.editionId = json["edition"]["editionId"].int ?? 0
                
                review.book?.bookId = json["edition"]["bookId"].int ?? 0
                review.book?.title = json["edition"]["title"].string ?? ""
                review.book?.author = json["edition"]["author"].string ?? ""
                review.book?.imageId = json["edition"]["imageId"].string ?? ""
                
                review.intro = json["review"]["intro"].string ?? ""
                review.value = json["review"]["value"].double ?? 0.0
                review.review = json["review"]["review"].string ?? ""
                review.reviewType = json["review"]["reviewType"].int ?? 0
                review.draftFlag = json["review"]["draftFlag"].bool ?? false
                review.evaluationTime = Date(timeIntervalSince1970: (json["review"]["evaluationTime"].double ?? 0.0) / 1000.0)
                
                review.user?.id = json["review"]["userId"].int ?? 0
                return review
            })
    }
}

class TotalVisitorUserEvaluationRequest: ListVisitorUserEvaluationRequest {
    override var path: String {
        return "book_v12/users/\(self.userId)/book_evaluations/search_total"
    }
}

class TotalVisitorUserEvaluationResponse: TotalResponse {
}
