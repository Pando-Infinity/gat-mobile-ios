//
//  SearchBookEdition.swift
//  gat
//
//  Created by jujien on 11/16/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

struct SearchBookEditionRequest: APIRequest {
    var path: String { return "book_edition/search" }
    
    var method: HTTPMethod { return .put }
    
    var headers: HTTPHeaders? {
        return [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer " + (Session.shared.accessToken ?? "")
        ]
    }
    
    var parameters: Parameters? {
        var criteria: [String: Any] = ["languagesPriority": self.languagesPriority]
        switch self.type {
        case .title(let text): criteria["title"] = text
        case .author(let text): criteria["authorName"] = text
        }
        return ["criteria": criteria, "pageNum": self.page, "pageSize": self.perPage]
    }
    
    var encoding: ParameterEncoding { return JSONEncoding.default }
    
    let languagesPriority: [Int] = Language.allCases.map { $0.rawValue }
        
    let type: SearchType
    
    let page: Int
    
    let perPage: Int
    
    
}

extension SearchBookEditionRequest {
    enum Language: Int, CaseIterable {
        case vietnamese = 1
        case english = 2
    }
    
    enum SearchType {
        case title(String)
        case author(String)
    }
}

struct SearchBookEditionResponse: APIResponse {
    typealias Resource = ([BookSharing], Int)
    
    func map(data: Data?, statusCode: Int) -> ([BookSharing], Int)? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return (json["data"]["pageData"].array?.compactMap({ (item) -> BookSharing? in
            let sharing = BookSharing()
            let book = BookInfo()
            book.editionId = item["editionId"].int ?? 0
            book.title = item["title"].string ?? ""
            book.author = item["authorName"].string ?? ""
            book.descriptionBook = item["description"].string ?? ""
            book.imageId = item["imageId"].string ?? ""
            book.isbn10 = item["isbn10"].string ?? ""
            book.isbn13 = item["isbn13"].string ?? ""
            book.rateAvg = item["summary"]["rateAvg"].double ?? 0.0
            book.saving = item["summary"]["saving"].bool ?? false 
            sharing.info = book
            sharing.sharingCount = item["summary"]["sharingCount"].int ?? 0
            sharing.reviewCount = item["summary"]["reviewCount"].int ?? 0
            sharing.id = book.editionId
            return sharing
        }) ?? [], json["data"]["total"].int ?? 0)
    }
    
    
}
