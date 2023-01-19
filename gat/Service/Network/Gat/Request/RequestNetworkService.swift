//
//  RequestNetworkService.swift
//  gat
//
//  Created by Vũ Kiên on 28/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import SwiftyJSON

class RequestNetworkService: NetworkService {
    static var shared: RequestNetworkService = RequestNetworkService()
    
    var dispatcher: Dispatcher
    
    fileprivate var service: ServiceNetwork
    var progress: Observable<Double> {
        return self.service.progress.asObserver()
    }
    
    fileprivate init() {
        self.dispatcher = APIDispatcher()
        self.service = ServiceNetwork.shared
    }
    
    func record(borrowStatus: [RecordStatus], lendStatus: [RecordStatus], keyword: String?, page: Int = 1, per_page: Int = 10) -> Observable<[BookRequest]> {
        return self.dispatcher
            .fetch(
                request: RecordRequest(borrowStatus: borrowStatus, lendStatus: lendStatus, keyword: keyword, page: page, perpage: per_page),
                handler: RecordResponse()
            )
    }
    
    func total(borrowStatus: [RecordStatus] = [.waitConfirm, .contacting, .borrowing], lendStatus: [RecordStatus] = [.waitConfirm, .contacting, .borrowing], keyword: String? = nil) -> Observable<Int> {
        return self.dispatcher
            .fetch(request: TotalRecordRequest(borrowStatus: borrowStatus, lendStatus: lendStatus, keyword: keyword, page: 1, perpage: 10), handler: TotalRecordResponse())
    }
    
    func info(bookRequest: BookRequest) -> Observable<(BookRequest, Int, Int, Int, Int)> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapFirst({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "share/get_request_info")
                    .method(.get)
                    .with(parameters: ["recordId": bookRequest.recordId])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> (BookRequest, Int, Int, Int, Int) in
                let resultInfo = json["data"]["resultInfo"]
                var sharingBook = 0
                var reviewBook = 0
                
                bookRequest.onHoldReasonId = resultInfo["onHoldReasonId"].int
                bookRequest.recordStatus = RecordStatus(rawValue: resultInfo["recordStatus"].int ?? -1)
                bookRequest.borrowExpectation = ExpectedTime(rawValue: resultInfo["borrowExpectation"].int ?? 1) ?? .aWeek
                
                bookRequest.book?.editionId = resultInfo["editionInfo"]["editionId"].int ?? 0
                bookRequest.book?.bookId = resultInfo["editionInfo"]["bookId"].int ?? 0
                bookRequest.book?.author = resultInfo["editionInfo"]["author"].string ?? ""
                bookRequest.book?.title = resultInfo["editionInfo"]["title"].string ?? ""
                bookRequest.book?.imageId = resultInfo["editionInfo"]["imageId"].string ?? ""
                
                bookRequest.owner?.id = resultInfo["ownerInfo"]["userId"].int ?? 0
                bookRequest.owner?.userTypeFlag = UserType(rawValue: resultInfo["ownerInfo"]["userTypeFlag"].int ?? 1) ?? .normal
                bookRequest.owner?.name = resultInfo["ownerInfo"]["name"].string ?? ""
                bookRequest.owner?.address = resultInfo["ownerInfo"]["address"].string ?? ""
                bookRequest.owner?.imageId = resultInfo["ownerInfo"]["imageId"].string ?? ""
                
                bookRequest.borrower?.id = resultInfo["borrowerInfo"]["userId"].int ?? 0
                bookRequest.borrower?.name = resultInfo["borrowerInfo"]["name"].string ?? ""
                bookRequest.borrower?.address = resultInfo["borrowerInfo"]["address"].string ?? ""
                bookRequest.borrower?.imageId = resultInfo["borrowerInfo"]["imageId"].string ?? ""
                bookRequest.borrower?.userTypeFlag = UserType(rawValue: resultInfo["borrowerInfo"]["userTypeFlag"].int ?? 1) ?? .normal
                
                if bookRequest.owner?.id == Session.shared.user?.id {
                    sharingBook = resultInfo["borrowerInfo"]["sharingCount"].int ?? 0
                    reviewBook = resultInfo["borrowerInfo"]["articleCount"].int ?? 0
                } else {
                    sharingBook = resultInfo["ownerInfo"]["sharingCount"].int ?? 0
                    reviewBook = resultInfo["ownerInfo"]["articleCount"].int ?? 0
                }
                
                
                if let approveTime = resultInfo["approveTime"].double {
                    bookRequest.approveTime = Date(timeIntervalSince1970: approveTime / 1000.0)
                }
                if let rejectTime = resultInfo["rejectTime"].double {
                    bookRequest.rejectTime = Date(timeIntervalSince1970: rejectTime / 1000.0)
                }
                if let requestTime = resultInfo["requestTime"].double {
                    bookRequest.requestTime = Date(timeIntervalSince1970: requestTime / 1000.0)
                }
                if let completeTime = resultInfo["completeTime"].double {
                    bookRequest.completeTime = Date(timeIntervalSince1970: completeTime / 1000.0)
                }
                if let borrowTime = resultInfo["borrowTime"].double {
                    bookRequest.borrowTime = Date(timeIntervalSince1970: borrowTime / 1000.0)
                }
                if let cancelTime = resultInfo["cancelTime"].double {
                    bookRequest.cancelTime = Date(timeIntervalSince1970: cancelTime / 1000.0)
                }
                if let lostTime = resultInfo["lostTime"].double {
                    bookRequest.lostTime = Date(timeIntervalSince1970: lostTime / 1000.0)
                }
                bookRequest.borrowType = BorrowType(rawValue: resultInfo["borrowType"].int ?? 1) ?? .userWithUser
                return (
                    bookRequest,
                    resultInfo["editionInfo"]["sharingCount"].int ?? 0,
                    resultInfo["editionInfo"]["reviewCount"].int ?? 0,
                    sharingBook,
                    reviewBook
                )
            })
    }
    
    func info(bookRequest: BookRequest) -> Observable<(Instance, Int, Int)> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapFirst({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "share/get_request_info")
                    .method(.get)
                    .with(parameters: ["recordId": bookRequest.recordId])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> (Instance, Int, Int) in
                let resultInfo = json["data"]["resultInfo"]
                let instance = Instance()
                instance.id = json["data"]["resultInfo"]["instanceId"].int ?? 0
                var sharingBook = 0
                var reviewBook = 0
                
                bookRequest.onHoldReasonId = resultInfo["onHoldReasonId"].int
                bookRequest.recordStatus = RecordStatus(rawValue: resultInfo["recordStatus"].int ?? -1)
                bookRequest.borrowExpectation = ExpectedTime(rawValue: resultInfo["borrowExpectation"].int ?? 1) ?? .aWeek
                
                bookRequest.book?.editionId = resultInfo["editionInfo"]["editionId"].int ?? 0
                bookRequest.book?.bookId = resultInfo["editionInfo"]["bookId"].int ?? 0
                bookRequest.book?.author = resultInfo["editionInfo"]["author"].string ?? ""
                bookRequest.book?.title = resultInfo["editionInfo"]["title"].string ?? ""
                bookRequest.book?.imageId = resultInfo["editionInfo"]["imageId"].string ?? ""
                
                instance.book = bookRequest.book!
                
                bookRequest.owner?.id = resultInfo["ownerInfo"]["userId"].int ?? 0
                bookRequest.owner?.userTypeFlag = UserType(rawValue: resultInfo["ownerInfo"]["userTypeFlag"].int ?? 1) ?? .normal
                bookRequest.owner?.name = resultInfo["ownerInfo"]["name"].string ?? ""
                bookRequest.owner?.address = resultInfo["ownerInfo"]["address"].string ?? ""
                bookRequest.owner?.imageId = resultInfo["ownerInfo"]["imageId"].string ?? ""
                bookRequest.owner?.address = resultInfo["ownerInfo"]["address"].string ?? ""
                bookRequest.owner?.about = resultInfo["ownerInfo"]["about"].string ?? ""
                
                let bookstop = Bookstop()
                bookstop.id = bookRequest.owner!.id
                bookstop.profile = bookRequest.owner
                let kind = BookstopKindOrganization()
                kind.totalEdition = resultInfo["ownerInfo"]["sharingCount"].int ?? 0
                kind.totalMemeber = resultInfo["ownerInfo"]["totalMember"].int ?? 0
                bookstop.kind = kind
                instance.owner = bookstop
                
                sharingBook = resultInfo["editionInfo"]["sharingCount"].int ?? 0
                reviewBook = resultInfo["editionInfo"]["articleCount"].int ?? 0
                
                bookRequest.borrower?.id = resultInfo["borrowerInfo"]["userId"].int ?? 0
                bookRequest.borrower?.name = resultInfo["borrowerInfo"]["name"].string ?? ""
                bookRequest.borrower?.address = resultInfo["borrowerInfo"]["address"].string ?? ""
                bookRequest.borrower?.imageId = resultInfo["borrowerInfo"]["imageId"].string ?? ""
                bookRequest.borrower?.userTypeFlag = UserType(rawValue: resultInfo["borrowerInfo"]["userTypeFlag"].int ?? 1) ?? .normal
                bookRequest.borrower?.about = resultInfo["borrowerInfo"]["about"].string ?? ""
                
                if let approveTime = resultInfo["approveTime"].double {
                    bookRequest.approveTime = Date(timeIntervalSince1970: approveTime / 1000.0)
                }
                if let rejectTime = resultInfo["rejectTime"].double {
                    bookRequest.rejectTime = Date(timeIntervalSince1970: rejectTime / 1000.0)
                }
                if let requestTime = resultInfo["requestTime"].double {
                    bookRequest.requestTime = Date(timeIntervalSince1970: requestTime / 1000.0)
                }
                if let completeTime = resultInfo["completeTime"].double {
                    bookRequest.completeTime = Date(timeIntervalSince1970: completeTime / 1000.0)
                }
                if let borrowTime = resultInfo["borrowTime"].double {
                    bookRequest.borrowTime = Date(timeIntervalSince1970: borrowTime / 1000.0)
                }
                if let cancelTime = resultInfo["cancelTime"].double {
                    bookRequest.cancelTime = Date(timeIntervalSince1970: cancelTime / 1000.0)
                }
                if let lostTime = resultInfo["lostTime"].double {
                    bookRequest.lostTime = Date(timeIntervalSince1970: lostTime / 1000.0)
                }
                bookRequest.borrowType = BorrowType(rawValue: resultInfo["borrowType"].int ?? 1) ?? .userWithUser
                instance.request = bookRequest
                return (instance, sharingBook, reviewBook)
            })
    }
    
    func update(owner bookRequest: BookRequest, newStatus: RecordStatus) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: AppConfig.sharedConfig.get("update_request_owner"))
                    .method(.post)
                    .with(parameters: ["recordId": bookRequest.recordId, "currentStatus": bookRequest.recordStatus!.rawValue, "newStatus": newStatus.rawValue])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> () in
                return ()
            })
    }
    
    func update(borrower bookRequest: BookRequest, newStatus: RecordStatus) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "share/update_request_by_borrower")
                    .method(.post)
                    .with(parameters: ["recordId": bookRequest.recordId, "currentStatus": bookRequest.recordStatus!.rawValue, "newStatus": newStatus.rawValue])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> () in
                return ()
            })
    }
    
    func request(to owner: Profile, borrow book: BookInfo, in expectation: ExpectedTime? = nil) -> Observable<BookRequest> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                var parameters = ["editionId": book.editionId, "bookId": book.bookId, "ownerId": owner.id]
                if let expectation = expectation {
                    parameters["expectation"] = expectation.rawValue
                }
                service
                    .builder()
                    .setPathUrl(path: AppConfig.sharedConfig.get("create_request_share"))
                    .method(.post)
                    .with(parameters: parameters)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> BookRequest in
                let data = json["data"]
                let resultInfo = data["resultInfo"]
                let bookRequest = BookRequest()
                bookRequest.recordId = resultInfo["recordId"].int ?? -1
                bookRequest.recordStatus = RecordStatus(rawValue: resultInfo["recordStatus"].int ?? -1)
                bookRequest.book = book
                bookRequest.owner = owner
                bookRequest.recordType = RequestType(rawValue: resultInfo["borrowType"].int ?? -1)
                if let expectation = expectation {
                    bookRequest.borrowExpectation = expectation
                }
                bookRequest.requestTime = Date(timeIntervalSince1970: (resultInfo["requestTime"].double ?? 0.0) / 1000.0)
                bookRequest.recordStatus = RecordStatus(rawValue: resultInfo["recordStatus"].int ?? -1)
                return bookRequest
            })
    }
}
