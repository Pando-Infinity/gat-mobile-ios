//
//  SuggestBookForUserInLocation.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

class SuggestBookForUserInLocationRequest: APIRequest {
    var path: String {
        return AppConfig.sharedConfig.get("book_suggestion")
    }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["page": self.page, "per_page": self.per_page, "range": self.range]
        if let userId = self.userId {
            params["userId"] = userId
        }
        if let location = self.location {
            params["curLat"] = location.latitude
            params["curLong"] = location.longitude
        }
        return params
    }
    
    fileprivate let userId: Int?
    fileprivate let location: CLLocationCoordinate2D?
    fileprivate let range: Int
    fileprivate let page: Int
    fileprivate let per_page: Int
    
    init(userId: Int?, location: CLLocationCoordinate2D?, range: Int, page: Int, per_page: Int) {
        self.userId = userId
        self.location = location
        self.range = range
        self.page = page
        self.per_page = per_page
    }
}

class SuggestBookForUserInLocationResponse: APIResponse {
    typealias Resource = ([BookSharing], Int)
    
    func map(data: Data?, statusCode: Int) -> ([BookSharing], Int)? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        let list = json["data"]["resultInfo"].array?.map({ (json) -> BookSharing in
            let bookSharing = BookSharing()
            bookSharing.info = BookInfo()
            bookSharing.id = json["bookId"].int ?? 0
            bookSharing.info?.editionId = json["editionId"].int ?? 0
            bookSharing.info?.title = json["title"].string ?? ""
            bookSharing.info?.imageId = json["imageId"].string ?? ""
            bookSharing.info?.author = json["author"].string ?? ""
            bookSharing.info?.rateAvg = json["rateAvg"].double ?? 0.0
            bookSharing.sharingCount = json["sharingCount"].int ?? 0
            bookSharing.reviewCount = json["reviewCount"].int ?? 0
            return bookSharing
        }) ?? []
        let range = json["data"]["range"].int ?? 0
        return (list, range)
    }
}

