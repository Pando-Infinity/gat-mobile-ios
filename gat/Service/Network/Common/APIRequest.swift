//
//  APIRequest.swift
//  gat
//
//  Created by Vũ Kiên on 02/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

protocol APIRequest {
    var path: String { get }
    
    var method: HTTPMethod { get }
    
    var parameters: Parameters? { get }
    
    var headers: HTTPHeaders? { get }
    
    var encoding: ParameterEncoding { get }
    
    func request(dispatcher: Dispatcher) -> Observable<Request>
}

extension APIRequest {
    var method: HTTPMethod {
        return .get
    }
    
    var parameters: Parameters? {
        return nil
    }
    
    var headers: HTTPHeaders? {
        return [
            "Accept-Language": "Accept-Language".localized(),
            "Authorization": Session.shared.accessToken ?? ""
        ]
    }
    
    var encoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    func request(dispatcher: Dispatcher) -> Observable<Request> {
        return Observable<Request>
            .just(
                Alamofire.request(dispatcher.host + self.path, method: self.method, parameters: self.parameters, encoding: self.encoding, headers: self.headers)
            )
    }
}
