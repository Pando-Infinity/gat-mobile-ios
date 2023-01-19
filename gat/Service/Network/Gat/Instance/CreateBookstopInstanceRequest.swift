//
//  CreateBookstopInstanceRequest.swift
//  gat
//
//  Created by jujien on 12/13/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

struct CreateBookstopInstanceRequest: APIRequest {
    var path: String { "instances/\(self.instanceId)/create_selfmanage_request" }
    
    var method: HTTPMethod { return .post }
    
    var parameters: Parameters? { ["expectation": self.expectation.rawValue] }
    
    var encoding: ParameterEncoding { return JSONEncoding.default }
    
    let instanceId: Int
    let expectation: ExpectedTime
}

struct CreateBookstopInstanceResponse: APIResponse {
    
    let instance: Instance
    
    func map(data: Data?, statusCode: Int) -> BookRequest? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        print(json)
        let data = json["data"]
        let bookRequest = BookRequest()
        bookRequest.book = self.instance.book
        bookRequest.borrower = self.instance.borrower
        bookRequest.owner = self.instance.owner?.profile
        bookRequest.onHoldReasonId = data["onHoldReasonId"].int
        bookRequest.recordId = data["recordId"].int ?? 0
        bookRequest.borrowExpectation = ExpectedTime(rawValue: data["borrowExpectation"].int ?? 1) ?? .aWeek
        if let approveTime = data["approveTime"].double {
            bookRequest.approveTime = .init(timeIntervalSince1970: approveTime / 1000.0)
        }
        if let rejectTime = data["rejectTime"].double {
            bookRequest.rejectTime = .init(timeIntervalSince1970: rejectTime / 1000.0)
        }
        bookRequest.requestTime = .init(timeIntervalSince1970: data["requestTime"].double ?? 0.0 / 1000.0)
        if let borrowTime = data["borrowTime"].double {
            bookRequest.borrowTime = .init(timeIntervalSince1970: borrowTime / 1000.0)
        }
        if let completeTime = data["completeTime"].double {
            bookRequest.completeTime = .init(timeIntervalSince1970: completeTime / 1000.0)
        }
        if let cancelTime = data["cancelTime"].double {
            bookRequest.cancelTime = .init(timeIntervalSince1970: cancelTime / 1000.0)
        }
        if let lostTime = data["lostTime"].double {
            bookRequest.lostTime = .init(timeIntervalSince1970: lostTime / 1000.0)
        }
        bookRequest.recordType = .borrowing
        bookRequest.recordStatus = RecordStatus(rawValue: data["recordStatus"].int ?? -1)
        bookRequest.borrowType = .userWithBookstop
        return bookRequest
    }
}
