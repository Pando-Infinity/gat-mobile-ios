//
//  AddAndUpdateReadingService.swift
//  gat
//
//  Created by macOS on 9/17/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//
import Foundation
import RxSwift
import Alamofire
import SwiftyJSON

class AddReadingNetwork {
    static var shared: AddReadingNetwork = AddReadingNetwork()
    
    
    fileprivate let searchDispatcher: Dispatcher
    
    fileprivate init() {
        self.searchDispatcher = SearchDispatcher()
    }
    
    func addReading(editionId:Int,pageNum:Int,pageRead:Int,readingStatusId:Int) -> Observable<(Book)> {
        return self.searchDispatcher.fetch(request: addReadingRequest(editionId: editionId, pageNum: pageNum, readPage: pageRead, readingStatusId: readingStatusId), handler: addReadingPesponse())
    }
    
    func updateReading(readingId:Int,pageNum:Int,pageRead:Int,readingStatusId:Int) -> Observable<(Book)> {
        return self.searchDispatcher.fetch(request: updateReadingRequest(readingId: readingId, pageNum: pageNum, readPage: pageRead, readingStatusId: readingStatusId) , handler: addReadingPesponse())
    }
}

struct updateReadingRequest:APIRequest {
    var path: String {return "user_reading"}
    
    var method: HTTPMethod {.patch}
    
    var parameters: Parameters? {
        return ["readingId": self.readingId, "pageNum":self.pageNum, "readPage":self.readPage,"readingStatusId":self.readingStatusId ]
    }
    
    var headers: HTTPHeaders? {
        var params: [String: String] = [:]
        params["Authorization"] = "Bearer " + (Session.shared.accessToken ?? "")
        return params
    }
    
    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }
    var readingId:Int
    var pageNum:Int
    var readPage:Int
    var readingStatusId:Int
}

struct addReadingRequest:APIRequest {
    var path: String {return "user_reading"}
    
    var method: HTTPMethod {.post}
    
    var parameters: Parameters? {
        return ["editionId": self.editionId, "pageNum":self.pageNum, "readPage":self.readPage,"readingStatusId":self.readingStatusId ]
    }
    
    var headers: HTTPHeaders? {
        var params: [String: String] = [:]
        params["Authorization"] = "Bearer " + (Session.shared.accessToken ?? "")
        return params
    }
    
    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }
    var editionId:Int
    var pageNum:Int
    var readPage:Int
    var readingStatusId:Int
}

struct addReadingPesponse:APIResponse {
    func map(data: Data?, statusCode: Int) -> Book? {
        guard let json = self.json(from: data, statusCode: statusCode)  else { return nil }
        let data = json["data"]
        let book = Book()
        print("JSOOOONNNNN: \(json["data"])")
        book.editionId = data["edition"]["editionSummary"]["editionId"].intValue
        book.numberPage = data["edition"]["numberOfPage"].intValue
        book.userRelation?.readPage = json["edition"]["readPage"].intValue
        return book
    }
    func error(data: Data?, statusCode: Int, url: String) -> ServiceError? {
        guard let data = data, statusCode >= 400 else { return nil }
        guard let json = try? JSON(data: data) else { return nil }
        print(json)
        let err = json["errors"].array?.first
        return ServiceError(domain: url, code: statusCode, userInfo: ["message": err?["details"].string ?? ""])
    }
}
