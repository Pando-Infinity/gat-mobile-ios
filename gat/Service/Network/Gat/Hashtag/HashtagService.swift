//
//  HashtagService.swift
//  gat
//
//  Created by jujien on 24/11/2020.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

struct HashtagService {
    
    static let shared = HashtagService()
    
    fileprivate let dispatcher: Dispatcher = DataDispatcher(host: AppConfig.sharedConfig.config(item: "api_url_v2")!)
    
    fileprivate init() { }
    
    func find(tagName: String, pageNum: Int, pageSize: Int) -> Observable<[Hashtag]> {
        self.dispatcher.fetch(request: GetHashtagRequest(tagName: tagName, pageNum: pageNum, pageSize: pageSize), handler: GetHashtagResponse())
    }
}
