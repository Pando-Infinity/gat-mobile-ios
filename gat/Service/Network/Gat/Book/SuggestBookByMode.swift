//
//  SuggestBookByMode.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

class SuggestBookByModeRequest: APIRequest {
    var path: String {
        return "editions/basic_suggestion"
    }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["mode": self.suggestMode.rawValue, "previous_days": self.previousDays, "page": self.page, "per_page": self.per_page]
        if let location = location {
            params["latitude"] = location.latitude
            params["longitude"] = location.longitude
        }
        return params
    }
    
    enum SuggestBookMode: Int {
        case topBorrowing = 1
        case topRating = 2
        case near = 3
        case history = 4
        
        var title: String {
            switch self {
            case .topBorrowing:
                return Gat.Text.BookSuggest.TOP_BORROWING_BOOK.localized()
            case .topRating:
                return Gat.Text.BookSuggest.TOP_RATING.localized()
            case .near:
                return Gat.Text.BookSuggest.BOOK_NEARBY_YOU.localized()
            case .history:
                return Gat.Text.BookSuggest.YOU_MIGHT_LIKE.localized()
            }
        }
    }
    
    fileprivate let suggestMode: SuggestBookMode
    fileprivate let previousDays: Int
    fileprivate let location: CLLocationCoordinate2D?
    fileprivate let page: Int
    fileprivate let per_page: Int
    
    init(suggestMode: SuggestBookMode, previousDays: Int, location: CLLocationCoordinate2D?, page: Int, per_page: Int) {
        self.suggestMode = suggestMode
        self.previousDays = previousDays
        self.location = location
        self.page = page
        self.per_page = per_page
    }
    
}

class SuggestBookByModeResponse: APIResponse {
    typealias Resource = [BookSharing]
    
    func map(data: Data?, statusCode: Int) -> [BookSharing]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]
            .array?
            .map({ (json) -> BookSharing in
                let bookSharing = BookSharing()
                bookSharing.id = json["edition"]["editionId"].int ?? 0
                bookSharing.info?.editionId = bookSharing.id
                bookSharing.info?.bookId = json["edition"]["bookId"].int ?? 0
                bookSharing.info?.title = json["edition"]["title"].string ?? ""
                bookSharing.info?.author = json["edition"]["author"].string ?? ""
                bookSharing.info?.imageId = json["edition"]["imageId"].string ?? ""
                bookSharing.info?.rateAvg = json["summary"]["rateAvg"].double ?? 0.0
                bookSharing.sharingCount = json["summary"]["sharingCount"].int ?? 0
                bookSharing.reviewCount = json["summary"]["reviewCount"].int ?? 0
                bookSharing.info?.saving = json["saving"].bool ?? false
                return bookSharing
            })
    }
}

