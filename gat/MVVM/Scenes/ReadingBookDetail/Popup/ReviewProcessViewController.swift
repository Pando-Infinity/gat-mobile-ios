//
//  ReviewProcessViewController.swift
//  gat
//
//  Created by jujien on 7/24/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Cosmos

class ReviewProcessViewController: UIViewController {
    
    class var segueIdentifier: String { "showReviewProcess" }

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var reviewButton: UIButton!
    @IBOutlet weak var lbYourReview: UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    
    let book: BehaviorRelay<BookInfo?> = .init(value: nil)
    fileprivate let post = BehaviorRelay<Post?>(value: nil)
//    fileprivate let review: BehaviorRelay<Review?> = .init(value: nil)
    weak var delegate: ReadingProcessDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.event()
        self.setupUI()
        self.setUpLocalizedString()
    }
    
    private func setUpLocalizedString(){
        self.titleLabel.text = "CONGRATULATIONS".localized()
        self.reviewButton.setTitle("EDIT_REVIEW".localized(), for: .normal)
        self.lbYourReview.text = "YOUR_REVIEW".localized()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        guard let user = Session.shared.user else { return }
        Observable.combineLatest(self.book.compactMap { $0 }.filter { $0.editionId != 0 }, Observable.from(optional: Session.shared.user))
            .flatMap { Repository<Post, PostObject>.shared.getAll(predicateFormat: "SUBQUERY(editionTags, $editionTag, $editionTag.editionId = %d).@count > 0 AND creator.id = %d AND SUBQUERY(categories, $category, $category.categoryId = %d).@count > 0", args: [$0.editionId, $1.id, PostCategory.REVIEW_CATEGORY_ID]) }
            .compactMap { $0.first }
            .bind(onNext: self.post.accept)
            .disposed(by: self.disposeBag)
        
        let remote = Observable.combineLatest(self.book.compactMap { $0 }.filter { $0.editionId != 0 }, Observable.from(optional: Session.shared.user))
            .filter { _ in Session.shared.isAuthenticated }
            .flatMap { (book, user) -> Observable<Post> in
                return PostService.shared.getMyReview(editionId: book.editionId)
                    .catchError { (error) -> Observable<Post> in
                        
                        return .empty()
                    }
            }
            .map { (post) -> Post in
                var p = post
                if let profile = Session.shared.user?.profile {
                    p.creator.profile = profile
                }
                return p
            }
        let rating = self.book.compactMap { $0 }.filter { $0.editionId != 0 }
            .filter { _ in Session.shared.isAuthenticated }
            .flatMap { (book) -> Observable<Review> in
            return ReviewNetworkService.shared.review(bookInfo: book)
                .catchError { (error) -> Observable<Review> in
                    HandleError.default.showAlert(with: error)
                    return .empty()
                }
        }
        .share()
        
        let getRating = rating.map { (review) -> Post in
            return .init(id: 0, title: "", intro: "", body: "", creator: .init(profile: review.user!, isFollowing: false), categories: [.init(categoryId: PostCategory.REVIEW_CATEGORY_ID, title: "Review")], postImage: .init(thumbnailId: review.book!.imageId, coverImage: review.book!.imageId, bodyImages: []), editionTags: [review.book!], rating: review.value)
        }
        
        let getArticle = Observable.combineLatest(remote, rating)
            .map { (post, review) -> Post in
                var p = post
                p.rating = review.value
                return p
            }
        Observable.of(getRating, getArticle)
            .merge()
            .do(onNext: self.post.accept)
            .filter { $0.id != 0 }
            .flatMap { Repository<Post, PostObject>.shared.save(object: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
        
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.rateView.rating = 0.0
        self.reviewLabel.numberOfLines = 2
        self.post.compactMap { $0?.rating }.bind { [weak self] value in
            self?.rateView.rating = value
            self?.backButton.isHidden = value == .zero
        }
        .disposed(by: self.disposeBag)
        
        self.post.map { (post) -> String in
            guard let post = post else { return "REMIND_RATE_BOOK".localized() }
            if post.intro.isEmpty {
                switch post.rating {
                case .zero: return "REMIND_RATE_BOOK".localized()
                case 1.0: return "RATE_DONT_LIKE".localized()
                case 2.0: return "RATE_OK".localized()
                case 3.0: return "RATE_GOOD".localized()
                case 4.0: return "RATE_GREAT".localized()
                default: return "RATE_EXCELLENT".localized()
                }
            } else {
                return post.intro
            }
        }
        .bind(to: self.reviewLabel.rx.text)
        .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }).disposed(by: self.disposeBag)
        
        let share = Observable.just(self)
            .flatMap { (vc) -> Observable<Double> in
                return .create { (observer) -> Disposable in
                    vc.rateView.didFinishTouchingCosmos = { value in
                        observer.onNext(value)
                    }
                    return Disposables.create()
                }
        }.withLatestFrom(self.post, resultSelector: { ($0, $1) })
            .share()

        share.compactMap { (value, review) -> String? in
            if review == nil || review!.intro.isEmpty || review!.body.isEmpty {
                var text = ""
                if value == 1 {
                    text += "RATE_DONT_LIKE".localized()
                } else if value == 2 {
                    text += "RATE_OK".localized()
                } else if value == 3 {
                    text += "RATE_GOOD".localized()
                } else if value == 4 {
                    text += "RATE_GREAT".localized()
                } else {
                    text += "RATE_EXCELLENT".localized()
                }
                return text
            }
            return nil
        }.bind(to: self.reviewLabel.rx.text).disposed(by: self.disposeBag)

        let sendData = share.map { (rating, post) -> Post in
            var post = post
            if post == nil {
                post = Post(title: "", intro: "", body: "", creator: PostCreator.init(profile: Session.shared.user!.profile!, isFollowing: false))
                post?.categories = [.init(categoryId: PostCategory.REVIEW_CATEGORY_ID, title: "Review")]
            }
            if post!.intro.isEmpty && post!.body.isEmpty {
                let value = rating
                var text = ""
                if value == 1 {
                    text += "RATE_DONT_LIKE".localized()
                } else if value == 2 {
                    text += "RATE_OK".localized()
                } else if value == 3 {
                    text += "RATE_GOOD".localized()
                } else if value == 4 {
                    text += "RATE_GREAT".localized()
                } else {
                    text += "RATE_EXCELLENT".localized()
                }
                post?.body = "<p>\(text)</p>"
                post?.intro = text
            }
            post?.rating = rating
            return post!
        }
        .withLatestFrom(self.book.compactMap { $0 }) { (post, book) -> Post in
            var post = post
            if post.title.isEmpty {
                post.title = "Review sách \(book.title)"
            }
            if post.postImage.thumbnailId.isEmpty && post.postImage.coverImage.isEmpty {
                post.postImage = .init(thumbnailId: book.imageId, coverImage: book.imageId, bodyImages: [])
            }
            post.editionTags = [book]
            return post
        }
        .share()
        
        let sendRating = sendData.map { (post) -> Review in
            let review = Review()
            review.reviewType = 2
            review.value = post.rating
            review.book = post.editionTags.first
            review.user = post.userTags.first
            return review
        }
        .flatMap { (review) -> Observable<(Review, Double)> in
            return ReviewNetworkService.shared.update(review: review)
        }
        
        let sendPost = sendData.filter{$0.id == 0}
            .flatMap { (post) -> Observable<Post> in
                return PostService.shared.update(post: post)
            }

        Observable.combineLatest(sendRating, sendPost)
            .catchError { (error) -> Observable<((Review, Double), Post)> in
                HandleError.default.showAlert(with: error)
                return .empty()
            }
            .map { (arg) -> Post in
                var post = arg.1
                post.rating = arg.0.0.value
                return post
            }
        .do (onNext: { [weak self] (post) in
                self?.post.accept(post)
                self?.delegate?.update(post: post)
            })
            .flatMap { Repository<Post, PostObject>.shared.save(object: $0) }
            .subscribe { [weak self] (_) in
                self?.backButton.isHidden = false
            }
            .disposed(by: self.disposeBag)
        
        self.reviewButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: {  (vc) in
                guard let post = vc.post.value else { return }
                vc.delegate?.readingProcess(readingProcess: vc, open: post)
            })
        .disposed(by: self.disposeBag)
    }

}
