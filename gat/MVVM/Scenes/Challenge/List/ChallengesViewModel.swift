import Foundation
import RxSwift
import RxCocoa
import Alamofire

final class ChallengesViewModel: ViewModelType {
    
    struct Input {
        let loadTrigger: Driver<Void>
    }
    
    struct Output {
        let indicator: Driver<Bool>
        let challenges: Driver<Challenges>
        let myChallenges: Driver<Challenges>
        let error: Driver<Error>
    }
    
    private let useCase: ChallengesUseCase
    
    init(useCase: ChallengesUseCase) {
        self.useCase = useCase
    }
    
    func transform(_ input: ChallengesViewModel.Input) -> ChallengesViewModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        let challenges = self.useCase.getChallenges()
        .trackActivity(indicator)
        .trackError(error)
        .asDriverOnErrorJustComplete()
        
        let myChallenges = self.useCase.getMyChallenges()
        .asDriverOnErrorJustComplete()
        
        return Output(
            indicator: indicator.asDriver(),
            challenges: challenges,
            myChallenges: myChallenges,
            error: error.asDriver()
        )
    }
}
