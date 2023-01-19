//
//  MyReviewTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 17/11/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift
import RxCocoa
import SwiftSoup

class MyReviewTableViewCell: UITableViewCell {
    
    class var identifier: String {
        return "myReviewCell"
    }

    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var writeReviewButton: UIButton!
    @IBOutlet weak var dateReviewLabel: UILabel!
    
    let review: BehaviorSubject<Review> = .init(value: Review())
    let book: BehaviorSubject<BookInfo> = .init(value: BookInfo())
    let post: BehaviorRelay<Post?> = .init(value: nil)
    weak var datasource: DetailCommentDataSource?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.sendUpdateReview()
        self.event()
    }
    
    // MARK: - Data
    
    fileprivate func sendUpdateReview() {
        Observable
            .combineLatest(
                self.rateChangeEvent(),
                self.post.compactMap { $0 }.distinctUntilChanged({ $0.id == $1.id })
            )
            .do (onNext: { [weak self] (_) in
                guard !Session.shared.isAuthenticated else { return }
                self?.rateView.rating = .zero
                HandleError.default.loginAlert()
            })
            .filter { _ in Session.shared.isAuthenticated }
            .flatMap { [weak self] (rating, post) -> Observable<(Post, Double)> in
                var p = post
                p.rating = rating
                let review = Review()
                review.reviewId = p.id
                review.book = post.editionTags.first
                review.value = rating
                review.draftFlag = false
                review.reviewType = 2
//                review.review = p.body
//                review.intro = p.intro
                return ReviewNetworkService.shared.update(review: review)
                    .catchError { [weak self] (error) -> Observable<(Review, Double)> in
                        self?.post.accept(self?.post.value)
                        HandleError.default.showAlert(with: error)
                        return .empty()
                    }
                    .map { (p, $0.1) }
            }
        .do (onNext: { [weak self] (post, rateAvg) in
                self?.datasource?.viewcontroller?.post.accept(post)
                self?.update(rateAvg: rateAvg)
                self!.sendPost(book: post.editionTags.first!, rating: rateAvg)
            })
            .filter { $0.0.id != 0 }
            .flatMap { Repository<Post, PostObject>.shared.save(object: $0.0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func sendPost(book: BookInfo,rating: Double){
        let user = Repository<UserPrivate, UserPrivateObject>.shared.get()
        
        var text = ""
        if rating == 1 {
            text += "RATE_DONT_LIKE".localized()
        } else if rating == 2 {
            text += "RATE_OK".localized()
        } else if rating == 3 {
            text += "RATE_GOOD".localized()
        } else if rating == 4 {
            text += "RATE_GREAT".localized()
        } else {
            text += "RATE_EXCELLENT".localized()
        }
        
        let title = String(format: "BOOK_REVIEW_POST".localized(), book.title)
        
        PostService.shared.getTotalMyReview(editionId: book.editionId)
            .catchError { (error) -> Observable<Int> in
                HandleError.default.showAlert(with: error)
                return .empty()
            }
            .filter{$0 <= 0}
            .subscribe(onNext: { (total) in
                var post = Post(title: title, intro: text, body: text, creator: .init(profile: (user?.profile)!, isFollowing: false))
                post.state = .published
                post.editionTags.append(book)
                post.categories = [.init(categoryId: 0, title: "")]
                post.rating = rating
                
                PostService.shared.update(post: post)
                    .catchError { (error) -> Observable<Post> in
                        HandleError.default.showAlert(with: error)
                        return .empty()
                    }.subscribe().disposed(by: self.disposeBag)
            })
            .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func update(rateAvg: Double) {
        if let book = try? self.book.value() {
            book.rateAvg = rateAvg
            Repository<BookInfo, BookInfoObject>.shared.save(object: book).subscribe().disposed(by: self.disposeBag)
            self.datasource?.viewcontroller?.bookDetailController?.bookDetailView.bookInfo.onNext(book)
        }
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.writeReviewButton.setAttributedTitle(.init(string: Gat.Text.BookDetail.WRITE_REVIEW_TITLE.localized(), attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.brownGrey]), for: .disabled)
        self.writeReviewButton.setAttributedTitle(.init(string: Gat.Text.BookDetail.WRITE_REVIEW_TITLE.localized(), attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue]), for: .normal)
        self.reviewLabel.numberOfLines = 2
        self.post.compactMap { (post) -> NSAttributedString? in
            guard let intro = post?.intro else { return nil }
            return .init(string: intro, attributes: [.font: UIFont.systemFont(ofSize: 12.0), .foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)])
        }
        .bind(to: self.reviewLabel.rx.attributedText)
        .disposed(by: self.disposeBag)
        
        self.post.compactMap { $0?.rating }.map { !$0.isZero }.bind(to: self.writeReviewButton.rx.isEnabled).disposed(by: self.disposeBag)
        
        self.post.compactMap { $0?.body.isEmpty }
            .map { $0 ? Gat.Text.BookDetail.WRITE_REVIEW_TITLE.localized() : Gat.Text.BookDetail.EDIT_REVIEW_TITLE.localized() }
            .bind(to: self.writeReviewButton.rx.title(for: .normal))
            .disposed(by: self.disposeBag)
        self.post.compactMap { $0?.rating }.bind { [weak self] value in
            self?.rateView.rating = value
        }
        .disposed(by: self.disposeBag)
        self.post.map { (post) -> Date in
            if post?.date.lastUpdate != nil {
                return post!.date.lastUpdate!
            } else if post?.date.publishedDate != nil {
                return post!.date.publishedDate!
            } else {
                return .init()
            }
        }
        .map { AppConfig.sharedConfig.stringFormatter(from: $0, format: LanguageHelper.language == .japanese ? "yyyy MMMM, dd" : "MMMM dd, yyyy") }
        .bind(to: self.dateReviewLabel.rx.text)
        .disposed(by: self.disposeBag)
    }
    
    //MARK: - Event
    func event() {
        self.writeReviewButton.rx.tap.do (onNext: { (_) in
            guard !Session.shared.isAuthenticated else { return }
            HandleError.default.loginAlert()
        })
        .filter { Session.shared.isAuthenticated }
        .withLatestFrom(self.post.compactMap { $0 })
        .subscribe(onNext: { [weak self] (post) in
            let step = StepCreateArticleViewController()

            let storyboard = UIStoryboard(name: "CreateArticle", bundle: nil)
            let createArticle = storyboard.instantiateViewController(withIdentifier: CreatePostViewController.className) as! CreatePostViewController
            createArticle.presenter = SimpleCreatePostPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimpleCreatePostRouter(viewController: createArticle, provider: step))
            step.add(step: .init(controller: createArticle, direction: .forward))
            self?.datasource?.viewcontroller?.bookDetailController?.navigationController?.pushViewController(step, animated: true)
            
        })
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func rateChangeEvent() -> Observable<Double> {
        .create { [weak self] (observer) -> Disposable in
            self?.rateView.didFinishTouchingCosmos = { rating in
                observer.onNext(rating)
            }
            return Disposables.create()
        }
    }

}
