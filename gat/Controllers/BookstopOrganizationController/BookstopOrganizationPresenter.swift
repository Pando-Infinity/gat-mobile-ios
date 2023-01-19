//
//  BookstopOrganizationPresenter.swift
//  gat
//
//  Created by jujien on 7/25/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

enum BookstopOrganizationItem: Int, Comparable {
   case image = 0
    case info = 1
    case tab = 2
    case myChallange = 3
    case challenge = 4
    case popularReview = 5
    case review = 6

    static func < (lhs: BookstopOrganizationItem, rhs: BookstopOrganizationItem) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

protocol BookstopOrganizationPresenter {
    
    var loading: Observable<Bool> { get }
    
    var bookstop: Observable<Bookstop> { get }
    
    var items: Observable<[SectionModel<BookstopOrganizationItem, Any>]> { get }
    
    func section(index: Int) -> BookstopOrganizationItem
    
    func item(indexPath: IndexPath) -> Any
    
    func editAction()
    
    func loadMore()
    
    func bookmark(review: Review)
    
    func getMyChallenge()
    
    func getChallenge()
    
    func getMemberPost()
    
    func getPopularPost()
    
    func reactPost(post:Post, reaction: Post.Reaction, count:Int)
    
    func bookmarkPost(post: Post)
}

struct SimpleBookstopOrganizationPresenter {

    fileprivate let _bookstop: BehaviorRelay<Bookstop>
    
    fileprivate let isLoading: BehaviorRelay<Bool>
    
    fileprivate let disposeBag: DisposeBag
    
    fileprivate let sectionItems: BehaviorRelay<[SectionModel<BookstopOrganizationItem, Any>]>
    
    fileprivate let page = BehaviorRelay<Int>(value: 1)
    
    fileprivate let router: BookstopOrganizationRouter
    
    init(bookstop: Bookstop, router: BookstopOrganizationRouter) {
        self.router = router
        self.sectionItems = .init(value: [
            .init(model: .tab, items: [
                [
                    NavigateHomeItem.init(image: #imageLiteral(resourceName: "tchallenge"), title: "CHALLENGE_TITLE".localized(), navigate: .challange, segueIdentifier: ListChallengeVC.segueIdentifier, newStatus: Session.shared.isAuthenticated && !AppConfig.sharedConfig.completPopupChallenge),
                    NavigateHomeItem.init(image: #imageLiteral(resourceName: "b"), title: Gat.Text.BookstopOrganization.BOOKS_TITLE.localized(), navigate: .reviews, segueIdentifier: "showListBookInBookstop", newStatus: false),
                    NavigateHomeItem.init(image: #imageLiteral(resourceName: "u"), title: "ACTIVITY".localized(), navigate: .gatup, segueIdentifier: ActivityBookstopOrganizationViewController.segueIdentifier, newStatus: false)
                ]
            ]),
            .init(model: .popularReview, items: [
                [
                ]
            ]),
            .init(model: .review, items: [
            ])
        ])
        self.disposeBag = .init()
        self.isLoading = .init(value: false)
        self._bookstop = .init(value: bookstop)
        self.getInfo(bookstop: bookstop)
        self.getItem()
    }
}

extension SimpleBookstopOrganizationPresenter: BookstopOrganizationPresenter {
    var bookstop: Observable<Bookstop> { self._bookstop.asObservable() }
    
    var loading: Observable<Bool> { self.isLoading.asObservable() }
    
    var items: Observable<[SectionModel<BookstopOrganizationItem, Any>]> { self.sectionItems.asObservable() }
    
    func section(index: Int) -> BookstopOrganizationItem {
        self.sectionItems.value[index].model
    }
    
    func editAction() {
        guard Session.shared.isAuthenticated else {
            self.router.showLogin()
            return
        }
        var bookstop = self._bookstop.value
        if let index = Session.shared.user?.bookstops.filter ({ ($0.kind as? BookstopKindOrganization)?.status != nil }).firstIndex(where: { $0.id == self._bookstop.value.id}) {
            bookstop = Session.shared.user!.bookstops[index]
        }
        self.router.showAlertEdit(bookstop: bookstop, action: self.requestStatus(_:))
    }
    
    func loadMore() {
        self.page.accept(self.page.value + 1)
    }
    
    func reactPost(post: Post, reaction: Post.Reaction, count: Int) {
        guard Session.shared.isAuthenticated else {
            self.sectionItems.accept(self.sectionItems.value)
            self.router.showLogin()
            return
        }
        var p = post
        p.id = post.id
        PostService.shared.reaction(postId: p.id, reactionId: reaction.rawValue, reactionCount: count)
            .catchError({ (error) -> Observable<()> in
                self.sectionItems.accept(self.sectionItems.value)
                return .empty()
            })
            .subscribe(onNext: { (_) in
                var items = self.sectionItems.value
                if let section = items.firstIndex(where: { $0.model == .review }) {
                    var posts = items[section].items.compactMap { $0 as? Post }
                    if let index = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[index] = post
                        posts[index].summary.reactCount += count
                        let increase = posts[index].userReaction.reactCount + count
                        posts[index].userReaction = .init(reactionId: reaction.rawValue, reactCount: increase)
                        items[section] = .init(model: .review, items: posts)
                        self.sectionItems.accept(items)
                    }
                }
            }).disposed(by: self.disposeBag)
    }
    
    func bookmarkPost(post: Post) {
        guard Session.shared.isAuthenticated else {
            self.sectionItems.accept(self.sectionItems.value)
            self.router.showLogin()
            return
        }
        var p = post
        p.id = post.id
        p.saving = !post.saving
        PostService.shared.saving(id: p.id, saving: p.saving)
        .catchError({ (error) -> Observable<()> in
            self.sectionItems.accept(self.sectionItems.value)
            return .empty()
        })
        .subscribe(onNext: { (_) in
            var items = self.sectionItems.value
            if let section = items.firstIndex(where: { $0.model == .review }) {
                var posts = items[section].items.compactMap { $0 as? Post }
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index] = p
                    items[section] = .init(model: .review, items: posts)
                    self.sectionItems.accept(items)
                }
            }
        }).disposed(by: self.disposeBag)
    }
    
    func bookmark(review: Review) {
        guard Session.shared.isAuthenticated else {
            self.sectionItems.accept(self.sectionItems.value)
            self.router.showLogin()
            return
        }
        let new = Review()
        new.reviewId = review.reviewId
        new.saving = !review.saving
        ReviewNetworkService.shared.bookmark(review: new)
            .catchError { (error) -> Observable<()> in
                self.sectionItems.accept(self.sectionItems.value)
                return .empty()
            }
        .subscribe(onNext: { (_) in
            review.saving = !review.saving
            var items = self.sectionItems.value
            if let section = items.firstIndex(where: { $0.model == .review }) {
                var reviews = items[section].items.compactMap { $0 as? Review }
                if let index = reviews.firstIndex(where: { $0.reviewId == review.reviewId }) {
                    reviews[index] = review
                    items[section] = .init(model: .review, items: reviews)
                    self.sectionItems.accept(items)
                }
            }
            CRNotifications.showNotification(type: .success, title: Gat.Text.Home.SUCCESS_TITLE.localized(), message: review.saving ? Gat.Text.Home.ADD_BOOKMARK_MESSAGE.localized() : Gat.Text.Home.REMOVE_BOOKMARK_MESSAGE.localized(), dismissDelay: 1.0)
        })
            .disposed(by: self.disposeBag)
    }
    
    func item(indexPath: IndexPath) -> Any {
        return self.sectionItems.value[indexPath.section].items[indexPath.row]
    }
}

extension SimpleBookstopOrganizationPresenter {
    fileprivate func getInfo(bookstop: Bookstop) {
        BookstopNetworkService.shared.info(bookstop: bookstop)
            .catchError(self.handle(error:))
            .subscribe(onNext: self._bookstop.accept)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getItem() {
        self.processBookstopItem()
        self.getMyChallenge()
        self.getChallenge()
        self.getMemberPost()
        self.getPopularPost()
//        self.getReview()
    }
    
    internal func getMemberPost() {
        Observable.combineLatest(self.page.asObservable(), self.bookstop)
            .flatMap { (page, bookstop) -> Observable<[Post]> in
                return PostService.shared.getBookStopMemberPost(pageNum: page, bookstopId: bookstop.id)
                .catchErrorJustReturn([])
        }
            .withLatestFrom(self.sectionItems.asObservable()) { (posts, items) -> [SectionModel<BookstopOrganizationItem, Any>] in
                guard !posts.isEmpty else { return items }
                var items = items
                if let index = items.firstIndex(where: { $0.model == .review }) {
                    var r = items[index].items.compactMap { $0 as? Post }
                    if self.page.value == 1 {
                        items[index] = .init(model: .review, items: posts)
                    } else {
                        r.append(contentsOf: posts)
                        items[index] = .init(model: .review, items: r)
                    }
                } else {
                    items.append(.init(model: .review, items: posts))
                    items.sort(by: { $0.model < $1.model})
                }
                return items
        }
        .subscribe(onNext: self.sectionItems.accept)
        .disposed(by: self.disposeBag)
    }
    
    internal func getPopularPost() {
        Observable.combineLatest(self.page.asObservable(), self.bookstop)
            .flatMap { (page, bookstop) -> Observable<[Post]> in
                return PostService.shared.getPopularBookStopPost(pageNum: page, bookstopId: bookstop.id)
                .catchErrorJustReturn([])
        }
            .withLatestFrom(self.sectionItems.asObservable()) { (posts, items) -> [SectionModel<BookstopOrganizationItem, Any>] in
                guard !posts.isEmpty else { return items }
                var items = items
                if let index = items.firstIndex(where: { $0.model == .popularReview }) {
                    var r = items[index].items.compactMap { $0 as? Post }
                    if self.page.value == 1 {
                        items[index] = .init(model: .popularReview, items: [posts])
                    } else {
                        r.append(contentsOf: posts)
                        items[index] = .init(model: .popularReview, items: [r])
                    }
                } else {
                    items.append(.init(model: .popularReview, items: [posts]))
                    items.sort(by: { $0.model < $1.model})
                }
                return items
        }
        .subscribe(onNext: self.sectionItems.accept)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func processBookstopItem() {
        self._bookstop.withLatestFrom(self.sectionItems.asObservable()) { (bookstop, items) -> [SectionModel<BookstopOrganizationItem, Any>] in
            var items = items
            if let index = items.firstIndex(where: { $0.model == .info }) {
                items[index] = .init(model: .info, items: [bookstop])
            } else {
                items.append(.init(model: .info, items: [bookstop]))
                items.sort(by: { $0.model < $1.model})
            }
            return items
        }
        .subscribe(onNext: self.sectionItems.accept)
        .disposed(by: self.disposeBag)
    }
    
    func getMyChallenge() {
        Application.shared.networkUseCaseProvider.makeChallengesUseCase().getMyBookstopChallenges(in: _bookstop.value)
            .withLatestFrom(self.sectionItems.asObservable()) { (data, items) -> [SectionModel<BookstopOrganizationItem, Any>] in
                guard let challenges = data.challenges, !challenges.isEmpty else { return items }
                var items = items
                if let index = items.firstIndex(where: { $0.model == .myChallange}) {
                    items[index] = .init(model: .myChallange, items: [challenges])
                } else {
                    items.append(.init(model: .myChallange, items: [challenges]))
                    items.sort(by: { $0.model < $1.model})
                }
                return items
        }.subscribe(onNext: self.sectionItems.accept)
            .disposed(by: self.disposeBag)
    }
    
    func getChallenge() {
        Application.shared.networkUseCaseProvider.makeChallengesUseCase().getBookstopChallenges(in: _bookstop.value)
            .withLatestFrom(self.sectionItems.asObservable()) { (data, items) -> [SectionModel<BookstopOrganizationItem, Any>] in
                guard let challenges = data.challenges, !challenges.isEmpty else { return items }
                var items = items
                if let index = items.firstIndex(where: { $0.model == .challenge}) {
                    items[index] = .init(model: .challenge, items: challenges)
                } else {
                    items.append(.init(model: .challenge, items: challenges))
                    items.sort(by: { $0.model < $1.model})
                }
                return items
        }.subscribe(onNext: self.sectionItems.accept)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getReview() {
        Observable.combineLatest(self.page.asObservable(), self.bookstop)
            .flatMap { (page, bookstop) -> Observable<[Review]> in
                return ReviewBookstopNetwork.shared.listBookstopReview(in: bookstop, page: page, per_page: 10)
                .catchErrorJustReturn([])
        }
            .withLatestFrom(self.sectionItems.asObservable()) { (reviews, items) -> [SectionModel<BookstopOrganizationItem, Any>] in
                guard !reviews.isEmpty else { return items }
                var items = items
                if let index = items.firstIndex(where: { $0.model == .review }) {
                    var r = items[index].items.compactMap { $0 as? Review }
                    if self.page.value == 1 {
                        items[index] = .init(model: .review, items: reviews)
                    } else {
                        r.append(contentsOf: reviews)
                        items[index] = .init(model: .review, items: r)
                    }
                } else {
                    items.append(.init(model: .review, items: reviews))
                    items.sort(by: { $0.model < $1.model})
                }
                return items
        }
        .subscribe(onNext: self.sectionItems.accept)
        .disposed(by: self.disposeBag)
    }
}

extension SimpleBookstopOrganizationPresenter {
    fileprivate func requestStatus(_ status: RequestBookstopStatus) {
        BookstopNetworkService.shared.request(in: self._bookstop.value, with: status, intro: nil)
            .catchError(self.handle(error:))
            .do(onNext: { (_) in
                var message = ""
                switch status {
                case .leave:
                    message = Gat.Text.BookstopOrganization.LEAVE_BOOKSTOP_SUCCESS_MESSAGE.localized()
                    break
                case .cancel:
                    message = Gat.Text.BookstopOrganization.CANCEL_REQUEST_SUCCESS_MESSAGE.localized()
                    break
                case .join:
                    message = Gat.Text.BookstopOrganization.JOIN_MESSAGE.localized()
                    break
                }
                CRNotifications.showNotification(type: .success, title: Gat.Text.BookstopOrganization.SUCCESS_TITLE.localized(), message: message, dismissDelay: 1.0)
            })
            .flatMap { (_) -> Observable<UserPrivate> in
                return UserNetworkService.shared.privateInfo()
                    .catchError(self.handle(error:))
            }
        .flatMap {
            Observable<UserPrivate>
                .combineLatest(
                    Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                    Observable<UserPrivate>.just($0),
                    resultSelector: { (old, new) -> UserPrivate in
                        old.update(new: new)
                        return old
                })
        }
        .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
    .subscribe()
        .disposed(by: self.disposeBag)
            
    }
}

extension SimpleBookstopOrganizationPresenter {
    fileprivate func handle<T>(error: Error) -> Observable<T> {
        HandleError.default.showAlert(with: error)
        self.isLoading.accept(false)
        return .empty()
    }
}
