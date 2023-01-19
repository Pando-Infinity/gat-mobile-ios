//
//  SharingBookUser.swift
//  gat
//
//  Created by Vũ Kiên on 04/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class SharingBookVisitorUserRequest: SharingBookUserRequest {
    
    override var path: String {
        return "book_v12/users/\(self.userId)/sharing_editions/search"
    }
    
    enum FilterOption: Int, CaseIterable {
        case available = 1
        case notAvailable = 0
    }
    
    override var parameters: Parameters? {
        var params = self.params
        params["sttFilter"] = self.options.map { $0.rawValue }
        return params
    }
    
    fileprivate let options: [FilterOption]
    fileprivate let userId: Int
    
    init(userId: Int, options: [FilterOption], keyword: String?, page: Int, perpage: Int) {
        self.options = options
        self.userId = userId
        super.init(keyword: keyword, page: page, perpage: perpage)
    }
}


struct SharingBookVisitorUserResponse: APIResponse {
    typealias Resource = [UserSharingBook]
    
    func map(data: Data?, statusCode: Int) -> [UserSharingBook]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"]
            .array?
            .map({ (json) -> UserSharingBook in
                let userSharingBook = UserSharingBook()
                userSharingBook.bookInfo.editionId = json["edition"]["editionId"].int ?? 0
                userSharingBook.bookInfo.bookId = json["edition"]["bookId"].int ?? 0
                userSharingBook.bookInfo.title = json["edition"]["title"].string ?? ""
                userSharingBook.bookInfo.imageId = json["edition"]["imageId"].string ?? ""
                userSharingBook.bookInfo.author = json["edition"]["author"].string ?? ""
                userSharingBook.bookInfo.rateAvg = json["summary"]["rateAvg"].double ?? 0.0
                userSharingBook.sharingCount = json["summary"]["sharingCount"].int ?? 0
                userSharingBook.reviewCount = json["summary"]["reviewCount"].int ?? 0
                
                userSharingBook.availableStatus = (json["availableStatus"].int ?? 0) == 1 ? true : false

                userSharingBook.profile.id = json["owner"]["userId"].int ?? 0
                userSharingBook.profile.name = json["owner"]["name"].string ?? ""
                userSharingBook.profile.imageId = json["owner"]["imageId"].string ?? ""
                userSharingBook.profile.address = json["owner"]["address"].string ?? ""
                userSharingBook.profile.userTypeFlag = UserType(rawValue: (json["owner"]["userTypeFlag"].int ?? 1)) ?? .normal
                userSharingBook.profile.about = json["owner"]["about"].string ?? ""
                
                if let recordId = json["loginUserBorrowrecord"]["recordId"].int {
                    userSharingBook.request = BookRequest()
                    userSharingBook.request?.recordId = recordId
                    userSharingBook.request?.book = userSharingBook.bookInfo
                    userSharingBook.request?.owner = userSharingBook.profile
                    userSharingBook.request?.borrower?.id = json["loginUserBorrowrecord"]["borrowerId"].int ?? 0
                    userSharingBook.request?.recordStatus = RecordStatus(rawValue: json["loginUserBorrowrecord"]["recordStatus"].int ?? -1)
                }
                
                return userSharingBook
            })
    }
}

class TotalSharingBookVisitorUserRequest: SharingBookVisitorUserRequest {
    override var path: String {
        return "book_v12/users/\(self.userId)/sharing_editions/search_total"
    }
}

class TotalSharingBookVisitorUserResponse: TotalResponse { }

