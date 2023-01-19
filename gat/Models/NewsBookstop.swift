//
//  NewBookstop.swift
//  gat
//
//  Created by jujien on 12/31/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON

class NewsBookstop {
    var id: Int
    var type: NewsType
    var title: String
    var description: String
    var bookstop: Bookstop?
    var date: Date = .init()
    var url: URL?
    fileprivate var refIds: String?
    fileprivate var refTypeId: Int?
    
    var isListImage: Bool { return self.refTypeId == 1 }
    
    var isListBook: Bool { return self.refTypeId == 2 }
    
    var lists: [Int]? { return self.refIds?.split(separator: ",").compactMap { Int($0) } }
    
    init(id: Int, type: Int, title: String, description: String, bookstop: Bookstop? = nil, refIds: String? = nil, refTypeId: Int? = nil) {
        self.id = id
        self.type = NewsType(rawValue: type) ?? .admin
        self.title = title
        self.description = description
        self.bookstop = bookstop
        self.refIds = refIds
        self.refTypeId = refTypeId
    }
    
    init() {
        self.id = 0
        self.type = .admin
        self.title = ""
        self.description = ""
    }
    
    init(json: JSON) {
        self.id = json["gatUpNewsId"].int ?? 0
        self.type = NewsType(rawValue: json["newsTypeId"].int ?? 1) ?? .admin
        self.title = json["title"].string ?? ""
        self.description = json["description"].string ?? ""
        let gatup = json["gatUp"]
        if let id = gatup["userId"].int {
            self.bookstop = .init()
            self.bookstop?.id = id
            self.bookstop?.profile?.id = id
            self.bookstop?.profile?.name = gatup["name"].string ?? ""
            self.bookstop?.profile?.imageId = gatup["imageId"].string ?? ""
            self.bookstop?.profile?.address = gatup["address"].string ?? ""
            self.bookstop?.profile?.userTypeFlag = .organization
            self.bookstop?.profile?.coverImageId = gatup["coverImageId"].string ?? ""
            self.bookstop?.profile?.about = gatup["about"].string ?? ""
            self.bookstop?.profile?.email = gatup["email"].string ?? ""
            self.bookstop?.profile?.location = .init(latitude: gatup["latitude"].double ?? 0.0, longitude: gatup["longitude"].double ?? 0.0)
            self.bookstop?.memberType = MemberType(rawValue: gatup["memberType"].int ?? 0) ?? .open
            let kind = BookstopKindOrganization()
            kind.totalEdition = gatup["summary"]["sharingCount"].int ?? 0
            kind.totalMemeber = gatup["summary"]["totalMember"].int ?? 0
            self.bookstop?.kind = kind
        }
        self.refIds = json["refIds"].string
        self.refTypeId = json["refTypeId"].int
        self.date = AppConfig.sharedConfig.convertToDate(from: json["createDate"].string ?? "", format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        if let url = json["url"].string {
            self.url = URL(string: url)
        }
    }
}

extension NewsBookstop {
    enum NewsType: Int {
        case admin = 1
        case gatup = 2
    }
}
