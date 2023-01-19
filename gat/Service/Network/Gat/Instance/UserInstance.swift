//
//  UserInstance.swift
//  gat
//
//  Created by Vũ Kiên on 02/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class BookInstanceRequest: SharingBookUserRequest {
    override var path: String {
        return "book_v12/self/book_instances/search"
    }
    
    enum InstanceFilterOption: Int, CaseIterable {
        case sharing = 1
        case borrowing = 2
        case lost = -1
    }
    
    override var parameters: Parameters? {
        var params = self.params
        params["sttFilter"] = self.status.map { $0.rawValue }
        return params
    }
    
    fileprivate var status: [InstanceFilterOption] = InstanceFilterOption.allCases
    
    convenience init(keyword: String?, page: Int, perpage: Int, status: [InstanceFilterOption]) {
        self.init(keyword: keyword, page: page, perpage: perpage)
        self.status = status
    }
}

struct BookInstanceResponse: APIResponse {
    typealias Resource = [Instance]
    
    func map(data: Data?, statusCode: Int) -> [Instance]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"]
            .array?
            .map({ (json) -> Instance in
                let instance = Instance()
                instance.id = json["bookinstance"]["instanceId"].int ?? 0
                instance.startShareDate = Date(timeIntervalSince1970: (json["bookinstance"]["startShareDate"].double ?? 0.0) / 1000.0)
                instance.sharingStatus = SharingStatus(rawValue: json["bookinstance"]["sharingStatus"].int ?? -1)
                instance.addDate = Date(timeIntervalSince1970: (json["bookinstance"]["userAddDate"].double ?? 0.0) / 1000.0)
                
                instance.book.editionId = json["edition"]["editionId"].int ?? 0
                instance.book.bookId = json["edition"]["bookId"].int ?? 0
                instance.book.title = json["edition"]["title"].string ?? ""
                instance.book.author = json["edition"]["author"].string ?? ""
                instance.book.rateAvg = json["edition"]["rateAvg"].double ?? 0.0
                instance.book.imageId = json["edition"]["imageId"].string ?? ""
                
                let userPrivate = UserPrivate()
                userPrivate.id = json["bookinstance"]["userId"].int ?? 0
                instance.owner = userPrivate
                if let borrowerId = json["borrower"]["userId"].int {
                    instance.borrower = Profile()
                    instance.borrower?.id = borrowerId
                    instance.borrower?.name = json["borrower"]["name"].string ?? ""
                    instance.borrower?.imageId = json["borrower"]["imageId"].string ?? ""
                    instance.borrower?.address = json["borrower"]["address"].string ?? ""
                    instance.borrower?.userTypeFlag = UserType(rawValue: json["borrower"]["userTypeFlag"].int ?? 1) ?? .normal
                    instance.borrower?.about = json["borrower"]["about"].string ?? ""
                }
                if let recordId = json["borrowrecord"]["recordId"].int {
                    instance.request = BookRequest()
                    instance.request?.recordId = recordId
                    instance.request?.book = instance.book
                    instance.request?.owner = instance.owner?.profile
                    instance.request?.borrower = instance.borrower
                    instance.request?.recordStatus = RecordStatus(rawValue: json["borrowrecord"]["recordStatus"].int ?? -1)
                }
                return instance
            }) ?? []
    }
}

class TotalBookInstanceRequest: BookInstanceRequest {
    override var path: String {
        return "book_v12/self/book_instances/search_total"
    }
}

class TotalBookInstanceResponse: TotalResponse { }
