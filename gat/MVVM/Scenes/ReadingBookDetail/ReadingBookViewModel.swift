import Foundation
import RxSwift
import RxCocoa

final class ReadingBookViewModel: ViewModelType {

    struct Input {
        let editionId: Int
        let addTrigger: PublishSubject<UpdateReadingPost>
        let updateTrigger: PublishSubject<UpdateReadingPost>
    }

    struct Output {
        let indicator: Driver<Bool>
        let addResponse: Observable<UpdateReadingResponse>
        let updateResponse: Observable<UpdateReadingResponse>
        let error: Driver<Error>
    }

    private let readingUseCase: ReadingUseCase
    private let reviewUseCase: ReviewUseCase

    init(readingUseCase: ReadingUseCase,
         reviewUseCase: ReviewUseCase) {
        self.readingUseCase = readingUseCase
        self.reviewUseCase = reviewUseCase
    }

    func transform(_ input: ReadingBookViewModel.Input) -> ReadingBookViewModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        
        let addResponse = input.addTrigger.flatMapLatest{ (readingPost) -> Driver<UpdateReadingResponse> in
            return self.readingUseCase.addReading(updateReadingPost: readingPost)
            .trackError(error)
            .asDriverOnErrorJustComplete()
        }
        
        let updateResponse = input.updateTrigger.flatMapLatest{ (readingPost) -> Driver<UpdateReadingResponse> in
            return self.readingUseCase.updateReading(updateReadingPost: readingPost)
            .trackError(error)
            .asDriverOnErrorJustComplete()
        }
        
        return Output(
            indicator: indicator.asDriver(),
            addResponse: addResponse,
            updateResponse: updateResponse,
            error: error.asDriver())
    }
}
