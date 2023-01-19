import Foundation
import RxSwift
import RxCocoa
import RxDataSources

final class ReadingHistoryViewModel: ViewModelType {
    
    struct Input {
        let loadTrigger: PublishSubject<UserReadingPut>
    }
    
    struct Output {
        let indicator: Driver<Bool>
        let readings: Observable<Readings>
        let error: Driver<Error>
    }
    
    private let useCaseReadings: ReadingsUseCase
    
    init(useCaseReadings: ReadingsUseCase) {
        self.useCaseReadings = useCaseReadings
    }
    
    func transform(_ input: ReadingHistoryViewModel.Input) -> ReadingHistoryViewModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        
        let readings = input.loadTrigger.flatMapLatest { userReadingPut -> Driver<Readings> in
                return self.useCaseReadings.getMyReadings(userReadingPut: userReadingPut)
                    .trackError(error)
                    .asDriverOnErrorJustComplete()
        }
        
        return Output(
            indicator: indicator.asDriver(),
            readings: readings,
            error: error.asDriver()
        )
    }
}
