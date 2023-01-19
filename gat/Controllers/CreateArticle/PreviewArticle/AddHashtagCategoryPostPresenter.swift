//
//  AddHashtagCategoryPostPresenter.swift
//  gat
//
//  Created by jujien on 9/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol AddHashtagCategoryPostPresenter {
    
    var isHashtagAutoComplete: Bool { get }
    
    var autoCompleteHashtags: Observable<[Hashtag]> { get }
    
    var currentHashtagSession: AutoCompletionSession? { get }
    
    var post: Observable<Post> { get }
    
    var updatePost: Observable<Post> { get }
    
    var categories: Observable<[PostCategory]> { get }
    
    var selected: BehaviorRelay<PostCategory?> { get set }
    
    func next()
    
    func refresh()
    
    func addHashtag(from text: String)
    
    func update(hashtag: String)
    
    func search(title: String)
    
    func sessionHashtagAutoComplete(_ session: AutoCompletionSession?)
    
    func removeSessionHashtag()
}

struct SimpleAddHashtagCategoryPostPresenter: AddHashtagCategoryPostPresenter {
    var isHashtagAutoComplete: Bool { self.autoHashtagComplete.value }
    
    var currentHashtagSession: AutoCompletionSession? { self.sessionHashtagAutpComplete.value }
    
    var autoCompleteHashtags: Observable<[Hashtag]> { self.hashtags.asObservable() }
    
    var post: Observable<Post> { self.article.asObservable() }
    
    var updatePost: Observable<Post> { self.update.asObservable() }
    
    var categories: Observable<[PostCategory]> { self.items.asObservable() }
    
    var selected: BehaviorRelay<PostCategory?>
    
    fileprivate let hashtags: BehaviorRelay<[Hashtag]> = .init(value: [])
    fileprivate let sessionHashtagAutpComplete = BehaviorRelay<AutoCompletionSession?>(value: nil)
    fileprivate let autoHashtagComplete: BehaviorRelay<Bool> = .init(value: false)
    fileprivate let update: BehaviorRelay<Post>
    fileprivate let article: BehaviorRelay<Post>
    fileprivate let items: BehaviorRelay<[PostCategory]> = .init(value: [])
    fileprivate let param = BehaviorRelay<DefaultParam>(value: .init(pageNum: 1))
    fileprivate let disposeBag = DisposeBag()
    
    init(post: Post) {
        self.update = .init(value: post)
        self.selected = .init(value: post.categories.first)
        self.article = .init(value: post)
        
        self.param
            .filter { _ in !post.isReview }
            .flatMap { PostService.shared.categories(title: $0.text ?? "", pageNum: $0.pageNum, pageSize: $0.pageSize).catchErrorJustReturn([]) }
            .withLatestFrom(self.param.asObservable(), resultSelector: { ($0, $1) })
            .withLatestFrom(self.items.asObservable()) { (arg0, items) -> [PostCategory] in
                let (result, param) = arg0
                var items = items
                if param.pageNum == 1 {
                    items = result
                } else {
                    items.append(contentsOf: result)
                }
                return items
            }
        .subscribe(onNext: self.items.accept)
        .disposed(by: self.disposeBag)
        
        self.selected.compactMap { $0 }.withLatestFrom(self.post) { (category, post) -> Post in
            var post = post
            post.categories = [category]
            return post
        }
        .subscribe(onNext: self.article.accept)
        .disposed(by: self.disposeBag)
        
        self.getHashtags()
    }
    
    func next() {
        self.param.accept(.init(text: self.param.value.text, pageNum: self.param.value.pageNum + 1, pageSize: self.param.value.pageSize))
    }
    
    func refresh() {
        self.param.accept(.init(text: self.param.value.text, pageNum: 1, pageSize: self.param.value.pageSize))
    }
    
    func search(title: String) {
        self.param.accept(.init(text: title, pageNum: 1, pageSize: self.param.value.pageSize))
    }
    
    func addHashtag(from text: String) {
        var post = self.article.value
        post.hashtags = text.split(separator: "#").map { String($0 )}.map({ (hashtag) -> Hashtag in
            return .init(id: 0, name: hashtag, count: 1)
        })
        self.article.accept(post)
    }
    
    func update(hashtag: String) {
        var post = self.article.value
        post.hashtags = hashtag.split(separator: "#").map { String($0 )}.map({ (hashtag) -> Hashtag in
            return .init(id: 0, name: hashtag, count: 1)
        })
        self.article.accept(post)
        self.update.accept(post)
        
    }
    
    func sessionHashtagAutoComplete(_ session: AutoCompletionSession?) {
        self.autoHashtagComplete.accept(session != nil)
        if session == nil {
            self.hashtags.accept([])
        }
        self.sessionHashtagAutpComplete.accept(session)
    }
    
    func removeSessionHashtag() {
        self.autoHashtagComplete.accept(false)
        self.hashtags.accept([])
        self.sessionHashtagAutpComplete.accept(nil)
    }
}

extension SimpleAddHashtagCategoryPostPresenter {
    fileprivate func getHashtags() {
        self.sessionHashtagAutpComplete
            .compactMap { $0?.filter }
            .flatMap {
                $0.isEmpty ? Observable<[Hashtag]>.just([]) : HashtagService.shared.find(tagName: $0, pageNum: 1, pageSize: 3)
            }
            .filter {  (_) -> Bool in
                return self.isHashtagAutoComplete
            }
            .subscribe(onNext: self.hashtags.accept)
            .disposed(by: self.disposeBag)
    }
}


