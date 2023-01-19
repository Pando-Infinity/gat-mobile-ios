//
//  SearchSuggestionService.swift
//  gat
//
//  Created by jujien on 6/5/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

class SearchSuggestionService: NetworkService {
    var dispatcher: Dispatcher
    
    static let shared = SearchSuggestionService()
    
    fileprivate init() {
        self.dispatcher = SearchDispatcher()
    }
    
    func suggestionTitle(text: String, size: Int = 10) -> Observable<[BookInfo]> {
        return self.dispatcher.fetch(request: SearchSuggestionBookRequest(title: text, size: size, type: .title), handler: SearchSuggestionBookResponse())
    }
    
    func suggestionAuthor(text: String, size: Int = 10) -> Observable<[BookInfo]> {
        return self.dispatcher.fetch(request: SearchSuggestionBookRequest(title: text, size: size, type: .author), handler: SearchSuggestionBookResponse())
    }
    
    func suggestionUser(text: String, size: Int = 10) -> Observable<[UserPublic]> {
        return self.dispatcher.fetch(request: SearchUserSuggestionRequest(keyword: text, size: size), handler: SearchUserSuggestionResponse())
    }
}
