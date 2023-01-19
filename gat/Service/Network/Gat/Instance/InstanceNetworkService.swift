//
//  InstanceNetworkService.swift
//  gat
//
//  Created by Vũ Kiên on 16/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON

class InstanceNetworkService: NetworkService {
    static var shared: InstanceNetworkService = InstanceNetworkService()
    
    var dispatcher: Dispatcher
    var dispatcherV2: SearchDispatcher
    
    fileprivate var service: ServiceNetwork
    var progress: Observable<Double> {
        return self.service.progress.asObserver()
    }
    
    fileprivate init() {
        self.dispatcher = APIDispatcher()
        self.dispatcherV2 = SearchDispatcher()
        self.service = ServiceNetwork.shared
    }
    
    func info(instanceId: Int) -> Observable<Instance> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "instances/\(instanceId)/info")
                    .method(.get)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> Instance in
                let instance = Instance()
                instance.parse(json: json["data"])
                return instance
            })
    }
    
    func info(instanceId: Int) -> Observable<(Instance, Int, Int, Int, Int)> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "instances/\(instanceId)/info")
                    .method(.get)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> (Instance, Int, Int, Int, Int) in
                let instance = Instance()
                instance.parse(json: json["data"])
                return (instance,
                        json["data"]["edition"]["sharingCount"].int ?? 0,
                        json["data"]["edition"]["reviewCount"].int ?? 0,
                        json["data"]["borrower"]["sharingCount"].int ?? 0,
                        json["data"]["borrower"]["reviewCount"].int ?? 0
                )
            })
    }
    
    func book(status: [BookInstanceRequest.InstanceFilterOption], keyword: String? = nil, page: Int = 1, per_page: Int = 10) -> Observable<[Instance]> {
        return self.dispatcher
            .fetch(request: BookInstanceRequest(keyword: keyword, page: page, perpage: per_page, status: status), handler: BookInstanceResponse())
    }
    
    func totalBook(option: [BookInstanceRequest.InstanceFilterOption] = [.sharing, .borrowing], keyword: String? = nil) -> Observable<Int> {
        return self.dispatcher
            .fetch(request: TotalBookInstanceRequest(keyword: keyword, page: 1, perpage: 10, status: option), handler: TotalBookInstanceResponse())
    }
    
    func remove(instance: Instance) -> Observable<()> {
        return self.dispatcherV2.fetch(request: DeleteInstanceRequest(instance: instance), handler: DeleteInstanceResponse())
    }
    
    func total(book: BookInfo) -> Observable<(Int, Int, Int, Int)> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: AppConfig.sharedConfig.get("book_instance_info"))
                    .method(.get)
                    .with(parameters: ["editionId": book.editionId])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> (Int, Int, Int, Int) in
                let data = json["data"]
                return (data["lostTotal"].int ?? 0, data["notSharingTotal"].int ?? 0, data["borrowingTotal"].int ?? 0, data["sharingTotal"].int ?? 0)
            })
    }
    
    func add(book: BookInfo, number: Int, sharingStatus: Bool) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                var parameters: [String: Any] = ["editionId": book.editionId, "bookId": book.bookId, "sharingStatus": sharingStatus ? 1 : 0, "numberOfBook": number]
                parameters["readingId"] = 0
                service
                    .builder()
                    .setPathUrl(path: AppConfig.sharedConfig.get("add_instance"))
                    .method(.post)
                    .with(parameters: parameters)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> () in
                return ()
//                var newReadingStatus = ReadingStatus
//                if newReadingStatus == nil {
//                    newReadingStatus = ReadingStatus()
//                }
//                newReadingStatus?.readingId = json["data"]["readingId"].int
//                newReadingStatus?.status = StatusReadBook(rawValue: json["data"]["readingStatus"].int ?? -1) ?? .remove
//                return newReadingStatus!
            })
    }
    
    func change(instance: Instance, with status: Bool) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: AppConfig.sharedConfig.get("change_status_book_instance_self"))
                    .method(.post)
                    .with(parameters: ["instanceId": instance.id, "sharingStatus": status.hashValue])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> () in
                return ()
            })
    }
    
    func create(requestTo instance: Instance, in expectation: ExpectedTime) -> Observable<BookRequest> {
        return self.dispatcher.fetch(request: CreateBookstopInstanceRequest(instanceId: instance.id, expectation: expectation), handler: CreateBookstopInstanceResponse(instance: instance))
    }
    
    func update(requestTo instance: Instance) -> Observable<BookRequest> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "instances/\(instance.id)/update_selfmanage_request")
                    .method(.post)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> BookRequest in
                let data = json["data"]
                let bookRequest = BookRequest()
                bookRequest.book = instance.book
                bookRequest.borrower = instance.borrower
                bookRequest.owner = instance.owner?.profile
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
            })
    }
}


struct DeleteInstanceRequest:APIRequest {
    var path: String {return "instances/\(instance.id)"}
    
    var headers: HTTPHeaders? {
        var params: [String: String] = [:]
        params["Accept-Language"] = "Accept-Language".localized()
        params["Authorization"] = "Bearer " + (Session.shared.accessToken ?? "")
        return params
    }
    
    var method: HTTPMethod { return .delete}
    
    let instance:Instance
}

struct DeleteInstanceResponse:APIResponse {
    func map(data: Data?, statusCode: Int) -> ()? {
        guard let json = self.json(from: data, statusCode: statusCode)  else { return nil }
        print(json)
        return ()
    }
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
