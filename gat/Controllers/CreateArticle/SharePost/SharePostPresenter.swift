//
//  SharePostPresenter.swift
//  gat
//
//  Created by jujien on 9/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol SharePostPresenter {
    var post: Observable<Post> { get }
}

struct SimpleSharePostPresenter: SharePostPresenter {
    var post: Observable<Post> { self.article.asObservable() }
    
    fileprivate let article: BehaviorRelay<Post>
    
    init(post: Post) {
        self.article = .init(value: post)
    }
}
