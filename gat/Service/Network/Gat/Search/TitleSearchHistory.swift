//
//  TitleSearchHistory.swift
//  gat
//
//  Created by jujien on 2/26/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RxSwift

class TitleBookSearchHistoryRequest: APIRequest {
    var path: String { return "search_v12/title_searched_keyword" }
    
    var method: HTTPMethod { return .post }
    
    fileprivate let keywords: [String]
    
    init(keywords: [String]) {
        self.keywords = keywords
    }
    
    func request(dispatcher: Dispatcher) -> Observable<Request> {
        var urlRequest = URLRequest(url: URL(string: dispatcher.host + self.path)!)
        urlRequest.httpMethod = self.method.rawValue
        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: self.keywords, options: [])
        var headers = self.headers
        headers?["Content-Type"] = "application/json"
        urlRequest.allHTTPHeaderFields = headers
        return Observable<Request>.just(Alamofire.request(urlRequest))
    }
}

class AuthorSearchHistoryRequest: APIRequest {
    var path: String { return "/search_v12/author_searched_keyword" }
    
    var method: HTTPMethod { return .post }
    
    fileprivate let keywords: [String]
    
    init(keywords: [String]) {
        self.keywords = keywords
    }
    
    func request(dispatcher: Dispatcher) -> Observable<Request> {
        var urlRequest = URLRequest(url: URL(string: dispatcher.host + self.path)!)
        urlRequest.httpMethod = self.method.rawValue
        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: self.keywords, options: [])
        var headers = self.headers
        headers?["Content-Type"] = "application/json"
        urlRequest.allHTTPHeaderFields = headers
        return Observable<Request>.just(Alamofire.request(urlRequest))
    }
}

class TitleSearchHistoryResponse: APIResponse {
    typealias Resource = ()
    
    func map(data: Data?, statusCode: Int) -> ()? {
        guard self.json(from: data, statusCode: statusCode) != nil else { return nil }
        return ()
    }
}
