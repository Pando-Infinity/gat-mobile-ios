//
//  HistoryService.swift
//  gat
//
//  Created by Vũ Kiên on 27/06/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON
import Alamofire

class HistoryNetworkService {
    static var shared: HistoryNetworkService = HistoryNetworkService()
    
    fileprivate var service: ServiceNetwork
    var progress: Observable<Double> {
        return self.service.progress.asObserver()
    }
    
    fileprivate init() {
        self.service = ServiceNetwork.shared
    }
    
    func searchHistory(type: HistoryType) -> Observable<[History]> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMap { (service) -> Observable<JSON> in
                service
                    .builder()
                    .method(.get)
                switch type {
                case .book:
                    service.setPathUrl(path: AppConfig.sharedConfig.get("history_book_title"))
                    break
                case .author:
                    service.setPathUrl(path: AppConfig.sharedConfig.get("history_book_author"))
                    break
                case .user:
                    service.setPathUrl(path: AppConfig.sharedConfig.get("history_user"))
                    break
                }
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            }
            .flatMapLatest { Observable<[History]>.just(History.parse(json: $0, type: type)) }
    }
}

