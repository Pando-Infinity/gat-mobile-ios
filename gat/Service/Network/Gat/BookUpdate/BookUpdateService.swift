import Foundation
import RxSwift

class BookUpdateSerivce: NetworkService {
    
    static let shared = BookUpdateSerivce()
    
    var dispatcher: Dispatcher
    
    fileprivate init() {
        self.dispatcher = APIDispatcher()
    }
    
    func totalWaiting() -> Observable<Int> {
        return self.dispatcher.fetch(request: TotalListBookWaitingRequest(), handler: TotalResponse())
    }
    
    func list(keyword: String = "", page: Int, per_page: Int = 10) -> Observable<[BookUpdate]> {
        return self.dispatcher.fetch(request: ListBookUpdateRequest(keyword: keyword, page: page, per_page: per_page), handler: ListBookUpdateResponse())
    }
}
