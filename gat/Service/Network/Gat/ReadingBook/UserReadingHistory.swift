//
//  UserReadingHistory.swift
//  gat
//
//  Created by jujien on 1/14/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct UserReadingRequest: APIRequest {
    var path: String { return "user_reading/self" }
    
    var parameters: Parameters? { return ["pageNum": self.page, "pageSize": self.perPage] }
    
    var headers: HTTPHeaders? {
        return [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": "Bearer " + (Session.shared.accessToken ?? "")
        ]
    }
    
    let page: Int
    let perPage: Int
    
}

struct UserReadingResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> [ReadingBook]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"].array?.map { ReadingBook(json: $0) }
            .map({ (readingBook) -> ReadingBook in
                if readingBook.editionId == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                    readingBook.user = Repository<UserPrivate, UserPrivateObject>.shared.get()!.profile!
                }
                return readingBook
            })
    }
}
