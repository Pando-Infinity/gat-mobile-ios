//
//  ReadingBookHistoryService.swift
//  gat
//
//  Created by jujien on 1/14/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import RxSwift

class ReadingBookHistoryService: NetworkService {
    
    static let shared = ReadingBookHistoryService()
    
    var dispatcher: Dispatcher
    
    fileprivate init() {
        self.dispatcher = SearchDispatcher()
    }
    
    func history(page: Int, per_page: Int = 10) -> Observable<[ReadingBook]> {
        return self.dispatcher.fetch(request: UserReadingRequest(page: page, perPage: per_page), handler: UserReadingResponse())
    }
}
