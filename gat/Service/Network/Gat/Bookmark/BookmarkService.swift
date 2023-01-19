import Foundation
import RxSwift
class BookmarkService: NetworkService {
    
    static let shared = BookmarkService()
    
    var dispatcher: Dispatcher
    
    fileprivate init () {
        self.dispatcher = APIDispatcher()
    }
    
    func listBook(keyword: String = "", page: Int, per_page: Int = 10) -> Observable<[BookInfo]> {
        return self.dispatcher.fetch(request: ListBookBookmarkRequest(keyword: keyword, page: page, per_page: per_page), handler: ListBookBookmarkResponse())
    }
    
    func totalBook() -> Observable<Int> {
        return self.dispatcher.fetch(request: TotalListBookBookmarkRequest(), handler: TotalBookmarkResponse())
    }
    
    func listReview(keyword: String = "", page: Int, per_page: Int = 10) -> Observable<[Review]> {
        return self.dispatcher.fetch(request: ListReviewBookmarkRequest(keyword: keyword, page: page, per_page: per_page), handler: ListReviewBookmarkResponse())
    }
    
    func totalReview() -> Observable<Int> {
        return self.dispatcher.fetch(request: TotalListReviewBookmarkRequest(), handler: TotalBookmarkResponse())
    }
}
