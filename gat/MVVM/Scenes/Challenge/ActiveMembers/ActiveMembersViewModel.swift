import Foundation
import RxSwift
import RxCocoa

final class ActiveMembersViewModel: ViewModelType {
    
    struct ParamLeaderBoard {
        var challengeId: Int
        var pageNum: Int
        var pageSize: Int = 20
    }
    
    struct Input {
        // Int value is challengeId
        let getData: PublishSubject<Int>
        let getLeaderBoards : BehaviorRelay<ParamLeaderBoard?>
        let getFriendLeaderBoards: BehaviorRelay<ParamLeaderBoard?>
    }
    
    struct Output {
        let indicator: Driver<Bool>
        let leaderBoards: Observable<LeaderBoards>
        let friendLeaderBoards: Observable<LeaderBoards>
        let error: Driver<Error>
    }
    
    private let useCaseLeaderBoards: LeaderBoardsUseCase
    
    init(useCase: LeaderBoardsUseCase) {
        self.useCaseLeaderBoards = useCase
    }
    
    func transform(_ input: ActiveMembersViewModel.Input) -> ActiveMembersViewModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        
        let leaderBoards = input.getLeaderBoards.compactMap { $0 }.flatMap { (param) -> Observable<LeaderBoards> in
            return self.useCaseLeaderBoards.getLeaderBoards(challengeId: param.challengeId, pageNum: param.pageNum, pageSize: param.pageSize)
            .trackActivity(indicator)
            .trackError(error)
        }
        
        let friendLeaderBoards = input.getFriendLeaderBoards.compactMap { $0 }.filter { _ in Session.shared.isAuthenticated }.flatMapLatest { (param) -> Observable<LeaderBoards> in
                return self.useCaseLeaderBoards.getFriendLeaderBoards(challengeId: param.challengeId, pageNum: param.pageNum, pageSize: param.pageSize)
                .trackError(error)
        }
        
        return Output(
            indicator: indicator.asDriver(),
            leaderBoards: leaderBoards,
            friendLeaderBoards: friendLeaderBoards,
            error: error.asDriver()
        )
    }
}
