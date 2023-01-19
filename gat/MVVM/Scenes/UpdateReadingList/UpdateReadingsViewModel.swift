import Foundation
import RxSwift
import RxCocoa
import RxDataSources

final class UpdateReadingsViewModel: ViewModelType {
    
    private let suggestBooks: BehaviorRelay<[Book]>
    private let myReadings: BehaviorRelay<[Reading]>
    
    var numberReadingBook: Int { return self.myReadings.value.count }
    
    var items: Observable<[SectionModel<String, Any>]> {
        return Observable.combineLatest(self.getReadings(), self.suggestBooks)
            .map { (readings, books) -> [SectionModel<String, Any>] in
                var array = [SectionModel<String, Any>(model: "READING_BOOK".localized(), items: readings.isEmpty ? [0] : readings)]
                if !books.isEmpty {
                    array.append(.init(model: "OTHER_BOOKS".localized(), items: books))
                }
                return array
        }
    }
    
    let canLoadMore: BehaviorRelay<Bool>
    let action: BehaviorRelay<CollectionAction>
    
    enum CollectionAction {
        case expand
        case collapse
    }
    
    struct Input {
        var pageBooks: Int
    }
    
    struct Output {
        let indicator: Driver<Bool>
        let error: Driver<Error>
    }
    
    private let useCaseBooks: BooksUseCase
    private let useCaseReadings: ReadingsUseCase
    
    init(useCaseBooks: BooksUseCase, useCaseReadings: ReadingsUseCase) {
        self.useCaseBooks = useCaseBooks
        self.useCaseReadings = useCaseReadings
        
        self.suggestBooks = .init(value: [])
        self.myReadings = .init(value: [])
        self.canLoadMore = .init(value: true)
        self.action = .init(value: .collapse)
    }
    
    func transform(_ input: UpdateReadingsViewModel.Input) -> UpdateReadingsViewModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        
        let userReadingPut = UserReadingPut(readingStatus: Reading.ReadingStatus.reading, pageNum: 1, pageSize: 100)
        let readings = self.useCaseReadings.getMyReadings(userReadingPut: userReadingPut)
        .subscribe(
            onNext: { result in
                guard let it = result.readings else { return }
                self.myReadings.accept(it)
        }, onError: { error in},
        onCompleted: { () in},
        onDisposed: {})
        
        var canLoadMore: Driver<Bool>
        let books = self.useCaseBooks.getTopBorrowingBooks(page: input.pageBooks, perPage: 10, previousDay: Int(AppConfig.sharedConfig.config(item: "previous_days")!)!)
        .subscribe(
            onNext: { result in
                print("result books")
                guard let it = result.books, it.count > 0 else {
                    self.canLoadMore.accept(false)
                    return
                }
                self.suggestBooks.accept(self.suggestBooks.value + it)
        },
            onError: { error in

        },
            onCompleted: { () in

        }, onDisposed: {})
        
        return Output(
            indicator: indicator.asDriver(),
            error: error.asDriver())
    }
    
    fileprivate func getReadings() -> Observable<[Any]> {
        return Observable.combineLatest(self.myReadings.asObservable(), self.action).map { (list, action) -> [Any] in
            if list.isEmpty { return [] }
            switch action {
            case .collapse: return list.count <= 3 ? list : list[0..<3].map { $0 }
            case .expand: return list
            }
        }
    }
    
    func toggleAction() {
        switch self.action.value {
        case .collapse: self.action.accept(.expand)
        case .expand: self.action.accept(.collapse)
        }
    }
}
