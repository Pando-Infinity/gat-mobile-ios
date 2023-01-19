//
//  ListBookSharing.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

class ListUserSharingBookRequest: APIRequest {
    var path: String {
        return "editions/\(self.editionId)/sharing_users"
    }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["page": self.page, "per_page": self.per_page, "sort_by": self.sortBy.rawValue]
        if let userId = self.userId {
            params["userId"] = userId
        }
        if let location = self.location {
            params["latitude"] = location.latitude
            params["longitude"] = location.longitude
        }
        return params
    }
    
    fileprivate let editionId: Int
    fileprivate let userId: Int?
    fileprivate let location: CLLocationCoordinate2D?
    fileprivate let activeFlag: Bool
    fileprivate let sortBy: SortOption
    fileprivate let page: Int
    fileprivate let per_page: Int
    
    init(editionId: Int, userId: Int?, location: CLLocationCoordinate2D?, activeFlag: Bool, sortBy: SortOption, page: Int, per_page: Int) {
        self.editionId = editionId
        self.userId = userId
        self.location = location
        self.activeFlag = activeFlag
        self.sortBy = sortBy
        self.page = page
        self.per_page = per_page
    }
}

class TotalListUserSharingBookRequest: APIRequest {
    var path: String {
        return "editions/\(self.editionId)/sharing_users_total"
    }
    
    var parameters: Parameters? {
        var params: Parameters = [:]
        if let userId = self.userId {
            params["userId"] = userId
        }
        if let location = self.location {
            params["latitude"] = location.latitude
            params["longitude"] = location.longitude
        }
        return params
    }
    
    fileprivate let editionId: Int
    fileprivate let userId: Int?
    fileprivate let location: CLLocationCoordinate2D?
    
    init(editionId: Int, userId: Int?, location: CLLocationCoordinate2D?) {
        self.editionId = editionId
        self.userId = userId
        self.location = location
    }
}

class ListUserSharingBookResponse: APIResponse {
    typealias Resource = [UserSharingBook]
    
    fileprivate let book: BookInfo
    fileprivate let user: Profile?
    
    init(book: BookInfo, user: Profile?) {
        self.book = book
        self.user = user
    }
    
    func map(data: Data?, statusCode: Int) -> [UserSharingBook]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        return json["data"].array?.map({ (json) -> UserSharingBook in
            let userSharingBook = UserSharingBook()
            userSharingBook.profile.id = json["userId"].int ?? 0
            userSharingBook.profile.name = json["name"].string ?? ""
            userSharingBook.profile.address = json["address"].string ?? ""
            userSharingBook.profile.userTypeFlag = UserType(rawValue: json["userTypeFlag"].int ?? 1) ?? .normal
            userSharingBook.profile.imageId = json["imageId"].string ?? ""
            
            userSharingBook.activeFlag = json["activeFlag"].bool ?? false
            userSharingBook.distance = json["distance"].double ?? 0.0
            userSharingBook.availableStatus = (json["sharingStatus"].int ?? 1) == 1 ? true : false
            
            if let recordId = json["recordId"].int, let recordStatus = json["recordStatus"].int {
                userSharingBook.request = BookRequest()
                userSharingBook.request?.recordId = recordId
                userSharingBook.request?.recordStatus = RecordStatus(rawValue: recordStatus)
                userSharingBook.request?.book = self.book
                userSharingBook.request?.borrower = self.user
                userSharingBook.request?.owner = userSharingBook.profile
            }
            
            userSharingBook.bookInfo = self.book
            userSharingBook.sharingCount = json["sharingCount"].int ?? 0
            userSharingBook.reviewCount = json["reviewCount"].int ?? 0
            return userSharingBook
        })
    }
}

class TotalListUserSharingBookResponse: APIResponse {
    typealias Resource = Int

    func map(data: Data?, statusCode: Int) -> Int? {
        return self.json(from: data, statusCode: statusCode)?["data"].int
    }
    
}
