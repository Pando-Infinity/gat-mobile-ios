//
//  ListNewReviewers.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class ListNewReviewerRequest: APIRequest {
    var path: String {
        return "reviews/top_reviewers"
    }
    
    var parameters: Parameters? {
        return ["previous_days": self.previousDay, "page": self.page, "per_page": self.per_page]
    }
    
    fileprivate let previousDay: Int
    fileprivate let page: Int
    fileprivate let per_page: Int
    
    init(previousDay: Int, page: Int, per_page: Int) {
        self.previousDay = previousDay
        self.page = page
        self.per_page = per_page
    }
}

class ListNewReviewerResponse: APIResponse {
    typealias Resource = [Reviewer]
    
    func map(data: Data?, statusCode: Int) -> [Reviewer]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"].array?.map({ (json) -> Reviewer in
            let reviewer = Reviewer()
            reviewer.profile?.id = json["userId"].int ?? 0
            reviewer.profile?.name = json["name"].string ?? ""
            reviewer.profile?.address = json["address"].string ?? ""
            reviewer.reviewCount = json["reviewCount"].int ?? 0
            reviewer.profile?.imageId = json["imageId"].string ?? ""
            reviewer.profile?.about = json["about"].string ?? ""
            reviewer.profile?.userTypeFlag = UserType(rawValue: json["userTypeFlag"].int ?? 0) ?? .normal
            return reviewer
        }) ?? []
    }
}


