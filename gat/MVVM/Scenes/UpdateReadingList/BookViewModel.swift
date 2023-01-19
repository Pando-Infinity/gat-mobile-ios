import Foundation
import RxSwift
import RxCocoa
import Alamofire

final class BookViewModel: ViewModelType {
    
    struct Input {
        let getBook: PublishSubject<Int>
    }
    
    struct Output {
        let indicator: Driver<Bool>
        let book: Observable<Book>
        let error: Driver<Error>
    }
    
    private let useCase: BookUseCase
    
    init(useCase: BookUseCase) {
        self.useCase = useCase
    }
    
    func transform(_ input: BookViewModel.Input) -> BookViewModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        
        let book = input.getBook.filter{$0 != 0}.flatMapLatest{ (editionId) -> Driver<Book> in
            return self.useCase.getBook(editionId: editionId)
            .trackError(error)
            .asDriverOnErrorJustComplete()
        }
        
        return Output(
            indicator: indicator.asDriver(),
            book: book,
            error: error.asDriver()
        )
    }
}
