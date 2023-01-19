import Foundation
import RxSwift
import RxCocoa
import Alamofire

final class ChallengeViewModel: ViewModelType {
    
    struct ActivityParam {
        var challengeId: Int
        var pageNum: Int
        var pageSize: Int = 10
    }

    struct Input {
        let getChallenge: PublishSubject<Int>
        let getActivities: BehaviorRelay<ActivityParam?>
        let joinChallenge: PublishSubject<Int>
    }

    struct Output {
        let indicator: Driver<Bool>
        let challenge: Observable<Challenge>
        let activities: Observable<CActivities>
        let joinResult: Observable<BaseModel>
        let error: Driver<Error>
    }
    
    private let useCaseChallenge: ChallengeUseCase
    private let useCaseActivities: CActivitiesUseCase
    private let useCaseJoinIn: JoinChallengeUseCase
    
    init(
        useCaseChallenge: ChallengeUseCase,
        useCaseActivities: CActivitiesUseCase,
        useCaseJoinIn: JoinChallengeUseCase
    ) {
        self.useCaseChallenge = useCaseChallenge
        self.useCaseActivities = useCaseActivities
        self.useCaseJoinIn = useCaseJoinIn
    }
    
    func transform(_ input: ChallengeViewModel.Input) -> ChallengeViewModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        
        let challenge = input.getChallenge.flatMapLatest { (challengeId) -> Driver<Challenge> in
                return self.useCaseChallenge.getChallenge(id: challengeId)
                .trackError(error)
                .asDriverOnErrorJustComplete()
        }
        
        let activities = input.getActivities.compactMap { $0 }.flatMapLatest { (param) -> Driver<CActivities> in
            return self.useCaseActivities.getCActivities(challengeId: param.challengeId, pageNum: param.pageNum, pageSize: param.pageSize)
                .asDriverOnErrorJustComplete()
        }
        
        let joinResult = input.joinChallenge.withLatestFrom(challenge, resultSelector: {($0, $1)})
            .flatMapLatest { (target, cl) -> Driver<BaseModel> in
                print("target: \(target), cl: \(cl.title)")
                return self.useCaseJoinIn.joinChallenge(challengeId: cl.id, targetNumber: target)
                    .trackError(error)
                    .asDriverOnErrorJustComplete()
        }
        
        return Output(
            indicator: indicator.asDriver(),
            challenge: challenge,
            activities: activities,
            joinResult: joinResult,
            error: error.asDriver()
        )
    }
}
