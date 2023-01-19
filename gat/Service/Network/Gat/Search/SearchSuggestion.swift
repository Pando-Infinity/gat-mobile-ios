//
//  SearchSuggestion.swift
//  gat
//
//  Created by jujien on 6/5/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct SearchSuggestionBookRequest: APIRequest {
    var path: String { return "book_edition/suggestion" }

    var parameters: Parameters? { return ["keyword": self.title, "size": self.size, "languagesPriority": self.languages, "type": self.type.rawValue] }
    
    var headers: HTTPHeaders? {
        return [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer " + (Session.shared.accessToken ?? "")
        ]
    }
    
    fileprivate let title: String
    fileprivate let size: Int
    fileprivate let languages: String
    fileprivate let type: TypeSuggest
    
    init(title: String, size: Int, languages: [Language] = Language.allCases, type: TypeSuggest) {
        self.title = title
        self.size = size
        self.languages = languages.map { String($0.rawValue) }.joined(separator: ",")
        self.type = type
    }
    
}

extension SearchSuggestionBookRequest {
    enum Language: Int, CaseIterable {
        case vietnamese = 1
        case english = 2
    }
    
    enum TypeSuggest: String {
        case all = "ALL"
        case title = "TITLE"
        case author = "AUTHOR"
    }
}

struct SearchSuggestionBookResponse: APIResponse {
    
    func map(data: Data?, statusCode: Int) -> [BookInfo]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"].array?.compactMap({ (item) -> BookInfo? in
            let book = BookInfo()
            book.editionId = item["editionId"].int ?? 0
            book.title = item["title"].string ?? ""
            book.author = item["authorName"].string ?? ""
            book.descriptionBook = item["description"].string ?? ""
            book.imageId = item["imageId"].string ?? ""
            return book
        })
    }
}
