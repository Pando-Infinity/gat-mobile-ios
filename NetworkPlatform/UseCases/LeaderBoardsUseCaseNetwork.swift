import Foundation
import RxSwift

final class LeaderBoardsUseCaseNetwork: LeaderBoardsUseCase {
    private let network: LeaderBoardsNetwork
    
    init(network: LeaderBoardsNetwork) {
        self.network = network
    }
    
    func getLeaderBoards(challengeId: Int, pageNum: Int, pageSize: Int) -> Observable<LeaderBoards> {
        return network.getLeaderBoards(challengeId: challengeId, pageNum: pageNum, pageSize: pageSize)
    }
    
    func getFriendLeaderBoards(challengeId: Int, pageNum: Int, pageSize: Int) -> Observable<LeaderBoards> {
        return network.getFriendLeaderBoards(challengeId: challengeId, pageNum: pageNum, pageSize: pageSize)
    }
    
}
