//
//  RecordRequest.swift
//  gat
//
//  Created by Vũ Kiên on 02/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class RecordRequest: APIRequest {
    var path: String {
        return "share_v12/self/borrowing_records/search"
    }
    
    var method: HTTPMethod { return .post }
    
    var encoding: ParameterEncoding { return JSONEncoding.default }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["page": self.page, "perPage": self.perpage]
        params["borrowStt"] = self.borrowStatus.map { $0.rawValue }
        params["lendStt"] = self.lendStatus.map { $0.rawValue }
        if let keyword = self.keyword, !keyword.isEmpty {
            params["keyword"] = keyword
        }
        return params
    }
    
    fileprivate let borrowStatus: [RecordStatus]
    fileprivate let lendStatus: [RecordStatus]
    fileprivate let keyword: String?
    fileprivate let page: Int
    fileprivate let perpage: Int
    
    init(borrowStatus: [RecordStatus], lendStatus: [RecordStatus], keyword: String?, page: Int, perpage: Int) {
        self.borrowStatus = borrowStatus
        self.lendStatus = lendStatus
        self.keyword = keyword
        self.page = page
        self.perpage = perpage
    }
}

struct RecordResponse: APIResponse {
    typealias Resource = [BookRequest]
    
    func map(data: Data?, statusCode: Int) -> [BookRequest]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"]
            .array?
            .map({ (json) -> BookRequest in
                let bookRequest = BookRequest()
                bookRequest.recordId = json["borrowrecord"]["recordId"].int ?? 0
                
                bookRequest.book?.editionId = json["edition"]["editionId"].int ?? 0
                bookRequest.book?.bookId = json["edition"]["bookId"].int ?? 0
                bookRequest.book?.title = json["edition"]["title"].string ?? ""
                bookRequest.book?.author = json["edition"]["author"].string ?? ""
                bookRequest.book?.imageId = json["edition"]["imageId"].string ?? ""
                
                bookRequest.borrower?.id = json["borrower"]["userId"].int ?? 0
                bookRequest.borrower?.name = json["borrower"]["name"].string ?? ""
                bookRequest.borrower?.imageId = json["borrower"]["imageId"].string ?? ""
                bookRequest.borrower?.address = json["borrower"]["address"].string ?? ""
                bookRequest.borrower?.userTypeFlag = UserType(rawValue: json["borrower"]["userTypeFlag"].int ?? 1) ?? .normal
                bookRequest.borrower?.about = json["borrower"]["about"].string ?? ""
                
                bookRequest.owner?.id = json["owner"]["userId"].int ?? 0
                bookRequest.owner?.name = json["owner"]["name"].string ?? ""
                bookRequest.owner?.address = json["owner"]["address"].string ?? ""
                bookRequest.owner?.userTypeFlag = UserType(rawValue: json["owner"]["userTypeFlag"].int ?? 1) ?? .normal
                bookRequest.owner?.about = json["owner"]["about"].string ?? ""
                
                if bookRequest.owner!.userTypeFlag == .organization {
                    bookRequest.borrowType = .userWithBookstop
                }
                
                bookRequest.recordStatus = RecordStatus(rawValue: json["borrowrecord"]["recordStatus"].int ?? -1)
                bookRequest.onHoldReasonId = json["borrowrecord"]["onHoldReasonId"].int
                if let approveTime = json["borrowrecord"]["approveTime"].double {
                    bookRequest.approveTime = Date(timeIntervalSince1970: approveTime / 1000.0)
                }
                if let rejectTime = json["borrowrecord"]["rejectTime"].double {
                    bookRequest.rejectTime = Date(timeIntervalSince1970: rejectTime / 1000.0)
                }
                if let requestTime = json["borrowrecord"]["requestTime"].double {
                    bookRequest.requestTime = Date(timeIntervalSince1970: requestTime / 1000.0)
                }
                if let completeTime = json["borrowrecord"]["completeTime"].double {
                    bookRequest.completeTime = Date(timeIntervalSince1970: completeTime / 1000.0)
                }
                if let borrowTime = json["borrowrecord"]["borrowTime"].double {
                    bookRequest.borrowTime = Date(timeIntervalSince1970: borrowTime / 1000.0)
                }
                if let cancelTime = json["borrowrecord"]["cancelTime"].double {
                    bookRequest.cancelTime = Date(timeIntervalSince1970: cancelTime / 1000.0)
                }
                if let lostTime = json["borrowrecord"]["lostTime"].double {
                    bookRequest.lostTime = Date(timeIntervalSince1970: lostTime / 1000.0)
                }
                return bookRequest
            })
    }
}

class TotalRecordRequest: RecordRequest {
    override var path: String {
        return "share_v12/self/borrowing_records/search_total"
    }
}

class TotalRecordResponse: TotalResponse { }
