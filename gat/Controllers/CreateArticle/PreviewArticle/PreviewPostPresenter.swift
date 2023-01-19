//
//  PreviewPostPresenter.swift
//  gat
//
//  Created by jujien on 9/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

protocol PreviewPostPresenter {
    
    var post: Observable<Post> { get }
    
    var items: Observable<[SectionModel<String, Any>]> { get }
    
    var loading: Observable<Bool> { get }
    
    func item(indexPath: IndexPath) -> Any
    
    func downloadImage(url: URL) -> Observable<UIImage>
    
    func publishPost()
    
    func addHashtagCategory()
    
    func backScreen()
}

struct SimplePreviewPostPresenter: PreviewPostPresenter {
        
    var items: Observable<[SectionModel<String, Any>]> { self._items.asObservable() }
    
    var loading: Observable<Bool> { self.isLoading.asObservable() }
    
    var post: Observable<Post> { self.article.asObservable() }
    
    fileprivate let _items: BehaviorRelay<[SectionModel<String, Any>]>
    
    fileprivate let imageUsecase: ImageUsecase
    fileprivate let router: PreviewPostRouter
    
    fileprivate let article: BehaviorRelay<Post>
    fileprivate let isLoading = BehaviorRelay<Bool>(value: false)
    
    fileprivate let disposeBag = DisposeBag()
    
    init(post: Post, imageUsecase: ImageUsecase, router: PreviewPostRouter) {
        self.article = .init(value: post)
        self.router = router
        self.imageUsecase = imageUsecase
        var items: [Any] = [post, post.body]
        if !post.editionTags.isEmpty {
            items.append(post.editionTags)
        }
        items.append(post.creator)
        self._items = .init(value: [
            .init(model: "", items: items)
        ])
    }
    
    func item(indexPath: IndexPath) -> Any {
        self._items.value[indexPath.section].items[indexPath.row]
    }
    
    func downloadImage(url: URL) -> Observable<UIImage> {
        guard let lastComponent = url.path.split(separator: "/").last, let size = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems?.last?.value else { return .empty() }
        let imageId = String(lastComponent)
        return self.imageUsecase.download(imageId: imageId, size: SizeImage(rawValue: size) ?? .o)
            .compactMap { UIImage(data: $0) }
    }
    
    func publishPost() {
        var post = self.article.value
        post.state = .published
        self.isLoading.accept(true)
        let update: Observable<Post>
        if post.isReview {
            let review = Review()
            review.book = post.editionTags.first
            review.user = post.creator.profile
            review.draftFlag = false
//            review.intro = post.intro
//            review.review = post.body
            review.reviewType = 2
            review.value = post.rating
            let updateRating = ReviewNetworkService.shared.update(review: review)
            let updatePost = PostService.shared.update(post: post)
            update = Observable.combineLatest(updateRating, updatePost)
                .catchError { (error) -> Observable<((Review, Double), Post)> in
                    self.router.showAlert(error: error)
                    self.isLoading.accept(false)
                    return .empty()
                }
                .map { $0.1 }
                .map({ (p) -> Post in
                    var copy = p
                    copy.rating = post.rating
                    return copy
                })
        } else {
            update = PostService.shared.update(post: post)
                .catchError { (error) -> Observable<Post> in
                    self.router.showAlert(error: error)
                    self.isLoading.accept(false)
                    return .empty()
                }
        }
        
        update
        .subscribe(onNext: { (post) in
            self.isLoading.accept(false)
            self.router.showCompete(post: post)
        })
            .disposed(by: self.disposeBag)
    }
    
    func addHashtagCategory() {
        self.router.openAddHashtagCategory(post: self.article.value)
            .subscribe(onNext: { (update) in
                self.article.accept(update)
            })
            .disposed(by: self.disposeBag)
    }
    
    func backScreen() {
        self.router.backScreen()
    }
}
