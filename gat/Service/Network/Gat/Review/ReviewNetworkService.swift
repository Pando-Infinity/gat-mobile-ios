//
//  ReviewNetworkService.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RxSwift

class ReviewNetworkService: NetworkService {
    static var shared: ReviewNetworkService = ReviewNetworkService()
    
    var dispatcher: Dispatcher
    
    fileprivate init() {
        self.dispatcher = APIDispatcher()
    }
    
    func newReviews(page: Int = 1, per_page: Int = 10) -> Observable<[Review]> {
        return self.dispatcher.fetch(request: ListNewReviewRequest(page: page, per_page: per_page), handler: ListNewReviewResponse())
    }
    
    func topReviewers(previousDay: Int = 7, page: Int = 1, per_page: Int = 10) -> Observable<[Reviewer]> {
        return self.dispatcher
            .fetch(request: ListNewReviewerRequest(previousDay: previousDay, page: page, per_page: per_page), handler: ListNewReviewerResponse())
    }
    
    func listReview(in book: BookInfo, page: Int = 1, per_page: Int = 10) -> Observable<[Review]> {
        return self.dispatcher.fetch(request: ListReviewBookRequest(editionId: book.editionId, page: page, per_page: per_page), handler: ListReviewBookResponse(book: book))
    }
    
    func review(bookInfo: BookInfo) -> Observable<Review> {
        return self.dispatcher
            .fetch(request: ReviewBookRequest(editionId: bookInfo.editionId), handler: ReviewBookResponse(book: bookInfo))
            .withLatestFrom(Repository<UserPrivate, UserPrivateObject>.shared.getFirst(), resultSelector: { (review, userPrivate) -> Review in
                review.user = userPrivate.profile
                return review
            })
    }
    
    func review(reviewId: Int) -> Observable<Review> {
        return self.dispatcher.fetch(request: ReviewRequest(reviewId: reviewId), handler: ReviewResponse())
    }
    
    func bookmark(review: Review) -> Observable<()> {
        return self.dispatcher.fetch(request: BookmarkReviewRequest(reviewId: review.reviewId, value: review.saving), handler: IgnoreResponse())
    }
    
    func update(review: Review) -> Observable<(Review, Double)> {
        return self.dispatcher.fetch(request: UpdateReviewRequest(review: review), handler: UpdateReviewResponse(review: review))
    }
    
    func reviews(option: ListEvaluationRequest.EvaluationFilterOption?, keyword: String?, page: Int = 1, per_page: Int = 10) -> Observable<[Review]> {
        return self.dispatcher
            .fetch(
                request: ListUserEvaluationRequest(keyword: keyword, option: option, page: page, perpage: per_page),
                handler: ListUserEvaluationResponse()
            )
    }
    
    func totalReviews(option: ListEvaluationRequest.EvaluationFilterOption = .all, keyword: String? = nil) -> Observable<Int> {
        return self.dispatcher
            .fetch(request: TotalListEvaluationRequest(keyword: keyword, option: option, page: 1, perpage: 10), handler: TotalListEvaluationResponse())
    }
    
    func reviews(of user: Profile, option: ListEvaluationRequest.EvaluationFilterOption, keyword: String?, page: Int = 1, per_page: Int = 10) -> Observable<[Review]> {
        return self.dispatcher
            .fetch(
                request: ListVisitorUserEvaluationRequest(userId: user.id, keyword: keyword, option: option, page: page, perpage: per_page),
                handler: ListVisitorUserEvaluationResponse()
            )
            .map({ (reviews) -> [Review] in
                reviews.forEach { $0.user = user }
                return reviews
            })
            
    }
    
    func totalReviews(of user: Profile, option: ListEvaluationRequest.EvaluationFilterOption = .all, keyword: String? = nil) -> Observable<Int> {
        return self.dispatcher
            .fetch(
                request: TotalVisitorUserEvaluationRequest(userId: user.id, keyword: keyword, option: option, page: 1, perpage: 10),
                handler: TotalVisitorUserEvaluationResponse()
            )
    }
    
    func remove(review: Review) -> Observable<()> {
        return self.dispatcher.fetch(request: RemoveReviewRequest(evaluationId: review.reviewId), handler: IgnoreResponse())
    }
}


class ReviewBookstopNetwork:NetworkService {
    static var shared: ReviewBookstopNetwork = ReviewBookstopNetwork()
    
    var dispatcher: Dispatcher
    
    fileprivate init() {
        self.dispatcher = SearchDispatcher()
    }
    func listBookstopReview(in bookstop:Bookstop,page: Int = 1, per_page:Int = 10) -> Observable<[Review]> {
        return self.dispatcher.fetch(request: ListBookstopReviewRequest(page: page, per_page: per_page, id: bookstop.id), handler: ListBookstopReviewResponse())
    }
}
