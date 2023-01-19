import RxSwift

public final class LeaderBoardsNetwork {
    private let network: Network<LeaderBoards>
    
    init(network: Network<LeaderBoards>) {
        self.network = network
    }
    
    func getLeaderBoards(challengeId: Int, pageNum: Int = 1, pageSize: Int = 10) -> Observable<LeaderBoards> {
        return network.getItem("challenges/\(challengeId)/leader_board", params: "?pageNum=\(pageNum)&pageSize=\(pageSize)")
    }
    
    func getFriendLeaderBoards(challengeId: Int, pageNum: Int = 1, pageSize: Int = 10) -> Observable<LeaderBoards> {
        return network.getItem("challenges/\(challengeId)/friend_leader_board", params: "?pageNum=\(pageNum)&pageSize=\(pageSize)")
    }
}
