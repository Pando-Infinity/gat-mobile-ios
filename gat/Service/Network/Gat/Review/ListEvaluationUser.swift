//
//  ListEvaluationUser.swift
//  gat
//
//  Created by Vũ Kiên on 02/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class ListEvaluationRequest: APIRequest {
    
    enum EvaluationFilterOption: Int {
        case all = -1
        case empty = 0
        case notEmpty = 1
    }
    
    var path: String { return "" }
    
    var method: HTTPMethod { return .post }
    
    var encoding: ParameterEncoding { return JSONEncoding.default }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["page": self.page, "perPage": self.perpage]
        if let option = self.option {
             params["reviewFilter"] = option.rawValue
        }
        if let keyword = self.keyword {
            params["keyWord"] = keyword
        }
        return params
    }
    
    fileprivate let keyword: String?
    fileprivate let option: EvaluationFilterOption?
    fileprivate let page: Int
    fileprivate let perpage: Int
    
    init(keyword: String?, option: EvaluationFilterOption?, page: Int, perpage: Int) {
        self.keyword = keyword
        self.option = option
        self.page = page
        self.perpage = perpage
        print(self.parameters)
    }
    
}

class ListUserEvaluationRequest: ListEvaluationRequest {
    override var path: String {
        return "book_v12/self/book_evaluations/search"
    }
}

struct ListUserEvaluationResponse: APIResponse {
    typealias Resource = [Review]
    
    func map(data: Data?, statusCode: Int) -> [Review]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"]
            .array?
            .map({ (json) -> Review in
                let review = Review()
                review.reviewId = json["review"]["reviewId"].int ?? 0
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
            }) ?? []
    }
}

class TotalListEvaluationRequest: ListUserEvaluationRequest {
    override var path: String {
        return "book_v12/self/book_evaluations/search_total"
    }
}

class TotalListEvaluationResponse: TotalResponse { }

