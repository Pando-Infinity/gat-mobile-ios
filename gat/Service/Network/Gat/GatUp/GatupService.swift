//
//  GatupService.swift
//  gat
//
//  Created by jujien on 12/31/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

class GatupService: NetworkService {
    
    static let shared = GatupService.init()
    var dispatcher: Dispatcher
    
    fileprivate init() {
        self.dispatcher = SearchDispatcher()
    }
    
    func news(page: Int, per_page: Int = 10) -> Observable<[NewsBookstop]> {
        return self.dispatcher.fetch(request: NewsGatupRequest(page: page, per_page: per_page), handler: NewsGatupResponse())
    }
}
