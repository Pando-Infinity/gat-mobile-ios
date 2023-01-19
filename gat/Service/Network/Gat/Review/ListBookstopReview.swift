//
//  ListBookstopReview.swift
//  gat
//
//  Created by macOS on 8/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class ListBookstopReviewRequest: APIRequest {
    var path: String {
        return "bookstop/\(self.id)/members/reviews?sorts=evaluationTime,DESC"
    }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["page": self.page, "per_page": self.per_page]
        if !self.sorts.isEmpty {
            let sorts = self.sorts.filter { $0.key != nil }.map { (sort) -> String in
                return "\(sort.key!),\(sort.ascending ? "ASC" : "DESC")"
            }.joined(separator: ",")
            params["sorts"] = sorts
        }
        return params
    }
    
    fileprivate let id: Int
    fileprivate let page: Int
    fileprivate let per_page: Int
    fileprivate let sorts: [NSSortDescriptor]
    
    init(page: Int, per_page: Int, id:Int, sorts: [NSSortDescriptor] = [NSSortDescriptor.init(key: "evaluationTime", ascending: false)]) {
        self.page = page
        self.per_page = per_page
        self.id = id
        self.sorts = sorts
    }
}

class ListBookstopReviewResponse: APIResponse {
    typealias Resource = [Review]
    
    func map(data: Data?, statusCode: Int) -> [Review]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print("JSONNNN:\(json)")
        return json["data"]["pageData"].array?.map({ (json) -> Review in
            let review  = Review()
            review.reviewId = json["evaluationId"].int ?? 0
            review.intro = json["intro"].string ?? ""
            review.reviewType = json["reviewType"].int ?? 0
            review.value = json["value"].double ?? 0.0
            review.draftFlag = json["draftFlag"].bool ?? false
            review.saving = json["saving"].bool ?? false
            review.review = json["review"].string ?? ""
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let date = dateFormatter.date(from: json["evaluationTime"].string ?? "") ?? Date()
            review.evaluationTime = date
                        
            review.book?.editionId = json["edition"]["editionId"].int ?? 0
            review.book?.title = json["edition"]["title"].string ?? ""
            review.book?.imageId = json["edition"]["imageId"].string ?? ""
            review.book?.author = json["edition"]["authorName"].string ?? ""
//          review.book?.rateAvg = json["pageData"]["edition"]["rateAvg"].double ?? 0.0
            
            review.user?.id = json["user"]["userId"].int ?? 0
            review.user?.name = json["user"]["name"].string ?? ""
            review.user?.address = json["user"]["address"].string ?? ""
            review.user?.userTypeFlag = UserType(rawValue: json["user"]["userTypeFlag"].int ?? 0) ?? .normal
            review.user?.imageId = json["user"]["imageId"].string ?? ""
            review.user?.about = json["user"]["about"].string ?? ""
            return review
        }) ?? []
    }
}
