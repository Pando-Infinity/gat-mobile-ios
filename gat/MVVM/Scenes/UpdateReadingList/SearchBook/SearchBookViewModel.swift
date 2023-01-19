import Foundation
import RxSwift
import RxCocoa

final class SearchBookViewModel: ViewModelType {
    
    struct Input {
        let searchBooks: PublishSubject<String>
    }
    
    struct Output {
        let indicator: Driver<Bool>
        let books: Observable<SearchBookResponse>
        let error: Driver<Error>
    }
    
    private let useCaseSearch: SearchBooksUseCase
    
    init(useCaseSearch: SearchBooksUseCase) {
        self.useCaseSearch = useCaseSearch
    }
    
    func transform(_ input: SearchBookViewModel.Input) -> SearchBookViewModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        
        let books = input.searchBooks.flatMapLatest{ (keyword) -> Driver<SearchBookResponse> in
            print("Start search keyword: \(keyword)")
            let searchBookPut = SearchBookPut(title: keyword, pageNum: 1, pageSize: 10)
            return self.useCaseSearch.searchBooks(searchBookPut: searchBookPut)
            .trackError(error)
            .asDriverOnErrorJustComplete()
        }
        
        return Output(
            indicator: indicator.asDriver(),
            books: books,
            error: error.asDriver()
        )
    }
}
