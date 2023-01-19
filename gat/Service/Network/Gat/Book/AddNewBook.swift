//
//  AddNewBook.swift
//  gat
//
//  Created by jujien on 2/26/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class AddNewBookRequest: APIRequest {
    var path: String { return "bookdata/add_missing_book" }
    
    var method: HTTPMethod { return .post }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["title": self.book.title, "counting": self.counting]
        if !self.book.descriptionBook.isEmpty {
            params["note"] = self.book.descriptionBook
        }
        return params
    }
    
    var encoding: ParameterEncoding { return JSONEncoding.default }
    
    fileprivate let book: BookInfo
    fileprivate let counting: Int
    
    init(book: BookInfo, counting: Int) {
        self.book = book
        self.counting = counting
    }
}

class AddNewBookResponse: APIResponse {
    typealias Resource = ()
    
    func map(data: Data?, statusCode: Int) -> ()? {
        guard self.json(from: data, statusCode: statusCode) != nil else { return nil }
        return ()
    }
}
