import Foundation
import RxSwift

public protocol LeaderBoardsUseCase {
    func getLeaderBoards(challengeId: Int, pageNum: Int, pageSize: Int) -> Observable<LeaderBoards>
    
    func getFriendLeaderBoards(challengeId: Int, pageNum: Int, pageSize: Int) -> Observable<LeaderBoards>
}
