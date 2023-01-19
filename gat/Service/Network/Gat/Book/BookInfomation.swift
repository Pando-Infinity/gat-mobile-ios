//
//  BookInfomation.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class BookInfomationRequest: APIRequest {
    var path: String {
        return AppConfig.sharedConfig.get("book_info")
    }
    
    var parameters: Parameters? {
        return ["editionId": self.editionId]
    }
    
    fileprivate let editionId: Int
    
    init(editionId: Int) {
        self.editionId = editionId
    }
}

class ListBookInformationRequest: APIRequest {
    var path: String {
        return "editions/infos"
    }
    
    var parameters: Parameters? {
        return ["ids": editions.map { "\($0)" }.joined(separator: ",")]
    }
    
    fileprivate let editions: [Int]
    
    init(editions: [Int]) {
        self.editions = editions
    }
}

struct BookISBNRequest: APIRequest {
    var path: String { return "book_edition/get_by_isbn" }
    
    var parameters: Parameters? { return ["isbn": self.isbn] }
    
    let isbn: String
}

class BookInfomationResponse: APIResponse {
    typealias Resource = BookInfo
    
    func map(data: Data?, statusCode: Int) -> BookInfo? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        let resultInfo = json["data"]["resultInfo"]
        let bookInfo = BookInfo()
        if resultInfo["editionId"].int != nil {
            bookInfo.descriptionBook = resultInfo["description"].string ?? ""
            bookInfo.editionId = resultInfo["editionId"].int ?? 0
            bookInfo.bookId = resultInfo["bookId"].int ?? 0
            bookInfo.title = resultInfo["title"].string ?? ""
            bookInfo.author = resultInfo["author"].array?.map { $0["authorName"].string ?? "" }.first ?? ""
            bookInfo.imageId = resultInfo["imageId"].string ?? ""
            bookInfo.rateAvg = resultInfo["rateAvg"].double ?? 0.0
            bookInfo.isbn10 = resultInfo["isbn10"].string ?? ""
            bookInfo.isbn13 = resultInfo["isbn13"].string ?? ""
            bookInfo.saving = resultInfo["saving"].bool ?? false
            bookInfo.totalPage = resultInfo["numberOfPage"].int ?? 0
            print("TOTALLLLLLL:\(bookInfo.totalPage)")
            return bookInfo
        }
        if let editionId = json["data"]["editionId"].int {
            bookInfo.editionId = editionId
            return bookInfo
        }
        return nil
    }
}

class BookInfomationRequestV2: APIRequest {
    var path: String {
        return "book_edition/\(editionId)"
    }
    
    var headers: HTTPHeaders? {
        return [
            "Authorization": "Bearer " + (Session.shared.accessToken ?? "")
        ]
    }
    fileprivate let editionId: Int
    
    init(editionId: Int) {
        self.editionId = editionId
        print("PATH BOOK: \(self.path)")
    }
}


class BookInfomationResponseV2: APIResponse {
    typealias Resource = BookInfo
    
    func map(data: Data?, statusCode: Int) -> BookInfo? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print("JSON:\(json)")
        let resultInfo = json["data"]
        let bookInfo = BookInfo()
        if resultInfo["editionId"].int != nil {
            bookInfo.descriptionBook = resultInfo["description"].string ?? ""
            bookInfo.editionId = resultInfo["editionId"].int ?? 0
            bookInfo.bookId = resultInfo["bookId"].int ?? 0
            bookInfo.title = resultInfo["title"].string ?? ""
            bookInfo.author = resultInfo["authorName"].string ?? ""
            bookInfo.imageId = resultInfo["imageId"].string ?? ""
            bookInfo.rateAvg = resultInfo["summary"]["rateAvg"].double ?? 0.0
            bookInfo.isbn10 = resultInfo["isbn10"].string ?? ""
            bookInfo.isbn13 = resultInfo["isbn13"].string ?? ""
            bookInfo.saving = resultInfo["saving"].bool ?? false
            bookInfo.totalPage = resultInfo["userRelation"]["reading"]["pageNum"].int ?? 0
            bookInfo.instanceCount = resultInfo["userRelation"]["instanceCount"].int ?? 0
            print("TOTALLLLLLL:\(bookInfo.totalPage)")
            return bookInfo
        }
        if let editionId = json["data"]["editionId"].int {
            bookInfo.editionId = editionId
            return bookInfo
        }
        return nil
    }
}

class ListBookInformationResponse: APIResponse {
    typealias Resource = [BookSharing]
    
    func map(data: Data?, statusCode: Int) -> [BookSharing]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]
            .array?
            .map({ (json) -> BookSharing in
                let bookSharing = BookSharing()
                bookSharing.id = json["editionId"].int ?? 0
                bookSharing.info?.editionId = json["editionId"].int ?? 0
                bookSharing.info?.bookId = json["bookId"].int ?? 0
                bookSharing.info?.title = json["title"].string ?? ""
                bookSharing.info?.author = json["author"].string ?? ""
                bookSharing.info?.imageId = json["imageId"].string ?? ""
                bookSharing.info?.rateAvg = json["rateAvg"].double ?? 0.0
                bookSharing.sharingCount = json["sharingCount"].int ?? 0
                bookSharing.reviewCount = json["reviewCount"].int ?? 0
                bookSharing.info?.saving = json["saving"].bool ?? false
                return bookSharing
            }) ?? []
    }
}

struct BookISBNResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> Int? {
        guard let json = self.json(from: data, statusCode: statusCode), let editionId = json["data"]["editionId"].int else { return nil }
        return editionId
    }
    
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
