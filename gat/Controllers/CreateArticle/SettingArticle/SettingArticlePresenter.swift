//
//  SettingArticlePresenter.swift
//  gat
//
//  Created by jujien on 8/21/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct PreviewArticleItem {
    var post: Post
    var type: PreviewType
    
    enum PreviewType {
        case small
        case medium
    }
}

protocol SettingArticlePresenter {
    
    var isBookAutoComplete: Bool { get }
    
    var isHashtagAutoComplete: Bool { get }
    
    var loading: Observable<Bool> { get }
    
    var post: Observable<Post> { get }
    
    var postUpdate: Observable<Post> { get }
    
    var previews: Observable<[PreviewArticleItem]> { get }
    
    var autoCompleteBooks: Observable<[BookSharing]> { get }
    
    var autoCompleteHashtags: Observable<[Hashtag]> { get }
    
    var currentBookSession: AutoCompletionSession? { get }
    
    var currentHashtagSession: AutoCompletionSession? { get }
    
    func select(category: PostCategory)
    
    func type(index: Int) -> PreviewArticleItem.PreviewType
    
    func addTagBook(_ book: BookInfo)
    
    func removeTagBook(id: Int)
        
    func sessionBookAutoComplete(_ session: AutoCompletionSession?)
    
    func sessionHashtagAutoComplete(_ session: AutoCompletionSession?)
    
    func removeSessionHashtag()
    
    func selectImage(_ image: UIImage)
    
    func save(hashtagText: String)
    
    func openSelectCategory()
    
    func openImagePicker(type: PreviewArticleItem.PreviewType)
    
    func backScreen()
    
}

class SimpleSettingArticlePresenter: SettingArticlePresenter {
    var post: Observable<Post> { self._post.asObservable() }
    
    var loading: Observable<Bool> { self.isLoading.asObservable() }
    
    var postUpdate: Observable<Post> { self.update.skip(1) }
    
    var previews: Observable<[PreviewArticleItem]> { self._previews.asObservable() }
    
    var autoCompleteBooks: Observable<[BookSharing]> { self.books.asObservable() }
    
    var autoCompleteHashtags: Observable<[Hashtag]> { self.hashtags.asObservable() }
    
    var isBookAutoComplete: Bool { self.autoBookComplete }
    
    var isHashtagAutoComplete: Bool { self.autoHashtagComplete }
    
    var currentBookSession: AutoCompletionSession? { self.sessionBookAutoComplete.value }
    
    var currentHashtagSession: AutoCompletionSession? { self.sessionHashtagAutpComplete.value }
    
    fileprivate var autoBookComplete: Bool = false
    fileprivate var autoHashtagComplete: Bool = false
    fileprivate let books: BehaviorRelay<[BookSharing]> = .init(value: [])
    fileprivate let hashtags: BehaviorRelay<[Hashtag]> = .init(value: [])
    fileprivate let sessionBookAutoComplete = BehaviorRelay<AutoCompletionSession?>(value: nil)
    fileprivate let sessionHashtagAutpComplete = BehaviorRelay<AutoCompletionSession?>(value: nil)
    fileprivate let _post: BehaviorRelay<Post>
    fileprivate let update: BehaviorRelay<Post>
    fileprivate let _previews: BehaviorRelay<[PreviewArticleItem]>
    fileprivate let isLoading = BehaviorRelay<Bool>(value: false)
    fileprivate let type: BehaviorRelay<PreviewArticleItem.PreviewType?> = .init(value: nil)
    
    fileprivate let imageUsecase: ImageUsecase
    fileprivate let router: SettingArticleRouter
    
    fileprivate let disposeBag = DisposeBag()
    

    init(post: Post, imageUsecase: ImageUsecase, router: SettingArticleRouter) {
        self.update = .init(value: post)
        self._post = .init(value: post)
        self._previews = .init(value: [])
        self._post.map { (post) -> [PreviewArticleItem] in
            return [
                .init(post: post, type: .small),
                .init(post: post, type: .medium)
            ]
        }
        .subscribe(onNext: self._previews.accept)
        .disposed(by: self.disposeBag)
        self.router = router
        self.imageUsecase = imageUsecase
        self.getBooks()
        self.getHashtags()
    }
    
    func select(category: PostCategory) {
        var post = self._post.value
        post.categories = [category]
        self._post.accept(post)
    }
    
    func type(index: Int) -> PreviewArticleItem.PreviewType {
        self._previews.value[index].type
    }
    
    func addTagBook(_ book: BookInfo) {
        var post = self._post.value
        post.editionTags.append(book)
        self._post.accept(post)
        self.autoBookComplete = false
        self.sessionBookAutoComplete.accept(nil)
        self.books.accept([])
    }
    
    func removeTagBook(id: Int) {
        var post = self._post.value
        post.editionTags.removeAll { (book) -> Bool in
            return book.editionId == id
        }
        self._post.accept(post)
    }
    
    
    func sessionBookAutoComplete(_ session: AutoCompletionSession?) {
        self.autoBookComplete = session != nil
        if session == nil {
            self.books.accept([])
        }
        self.sessionBookAutoComplete.accept(session)
    }
    
    func sessionHashtagAutoComplete(_ session: AutoCompletionSession?) {
        self.autoHashtagComplete = session != nil
        if session == nil {
            self.hashtags.accept([])
        }
        self.sessionHashtagAutpComplete.accept(session)
    }
    
    func removeSessionHashtag() {
        self.autoHashtagComplete = false
        self.hashtags.accept([])
        self.sessionHashtagAutpComplete.accept(nil)
    }
    
    func selectImage(_ image: UIImage) {
        self.isLoading.accept(true)
        var post = self._post.value
        if let type = self.type.value {
            switch type {
            case .small: post.postImage.thumbnailId = image.toBase64()
            case .medium: post.postImage.coverImage = image.toBase64()
            }
        }
        post.postImage.coverImage = image.toBase64()
        self._previews.accept([.init(post: post, type: .small), .init(post: post, type: .medium)])
        self.imageUsecase.upload(image: image, compressionQuality: 0.8, maxBytes: 1000 * 1000)
            .catchError({ (error) -> Observable<String> in
                self.isLoading.accept(false)
                self.router.showAlert(error: error)
                self._post.accept(self._post.value)
                return .empty()
            })
            .subscribe(onNext: { (imageId) in
                self.isLoading.accept(false)
                var post = self._post.value
                if let type = self.type.value {
                    switch type {
                    case .small: post.postImage.thumbnailId = imageId
                    case .medium: post.postImage.coverImage = imageId
                    }
                } else {
                    post.postImage.coverImage = imageId
                    post.postImage.thumbnailId = imageId
                }
                self.type.accept(nil)
                self._post.accept(post)
            })
            .disposed(by: self.disposeBag)
    }
    
    func save(hashtagText: String) {
        var post = self._post.value
        post.hashtags = hashtagText.split(separator: "#").map { String($0 )}.map({ (hashtag) -> Hashtag in
            return .init(id: 0, name: hashtag, count: 1)
        })
        self._post.accept(post)
        self.update.accept(post)
        self.router.backScreen()
    }
    
    func openSelectCategory() {
        self.router.openSelectArticle(selected: self._post.value.categories.first).compactMap { $0 }.subscribe(onNext: self.select(category:)).disposed(by: self.disposeBag)
    }
    
    func openImagePicker(type: PreviewArticleItem.PreviewType) {
        self.type.accept(type)
        self.router.showImagePicker()
    }
    
    func backScreen() {
        self.router.backScreen()
    }
}

extension SimpleSettingArticlePresenter {
    fileprivate func getBooks() {
        self.sessionBookAutoComplete.compactMap { $0?.filter }
            .flatMap {
                $0.isEmpty ? Observable<[BookSharing]>.just([]) : SearchNetworkService.shared.book(title: $0, page: 10)
                    .catchErrorJustReturn(([], 0))
                    .map { $0.0 }
        }
        .filter({ [weak self] (_) -> Bool in
            guard let value = self?.isBookAutoComplete else { return false }
            return value
        })
        .subscribe(onNext: self.books.accept)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func getHashtags() {
        self.sessionHashtagAutpComplete
            .compactMap { $0?.filter }
            .flatMap {
                $0.isEmpty ? Observable<[Hashtag]>.just([]) : HashtagService.shared.find(tagName: $0, pageNum: 1, pageSize: 10)
            }
            .filter { [weak self] (_) -> Bool in
                guard let value = self?.isHashtagAutoComplete else { return false }
                return value
            }
            .subscribe(onNext: self.hashtags.accept)
            .disposed(by: self.disposeBag)
    }
}
