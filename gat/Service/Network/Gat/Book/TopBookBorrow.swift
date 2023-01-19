//
//  TopBorrowRequest.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class TopBookBorrowRequest: APIRequest {
    var path: String {
        return "editions/top_borrow"
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

class TopBookBorrowResponse: APIResponse {
    typealias Resource = [BookSharing]
    
    func map(data: Data?, statusCode: Int) -> [BookSharing]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return [] }
        return json["data"].array?
            .map({ (json) -> BookSharing in
                let bookSharing = BookSharing()
                bookSharing.info = BookInfo()
                bookSharing.info?.parse(json: json)
                bookSharing.id = json["editionId"].int ?? 0
                bookSharing.rateCount = json["rateCount"].int ?? 0
                bookSharing.reviewCount = json["reviewCount"].int ?? 0
                bookSharing.sharingCount = json["sharingCount"].int ?? 0
                bookSharing.info?.saving = json["saving"].bool ?? false
                return bookSharing
            })
    }
}
