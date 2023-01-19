import RxSwift

public final class ChallengesNetwork {
    private let network: Network<Challenges>
    
    init(network: Network<Challenges>) {
        self.network = network
    }
    
    func getChallenges() -> Observable<Challenges> {
        return network.getData("challenges?joinStatusFilter=\(JoinStatus.all.rawValue)")
    }
    
    func getMyChallenge() -> Observable<Challenges> {
        return network.getData("user/self/challenges")
    }
    
    func getBookstopChallenges(in bookstop:Bookstop) -> Observable<Challenges> {
        return network.getData("bookstop/\(bookstop.id)/challenges?joinStatusFilter=\(JoinStatus.notJoin.rawValue)")
    }
    
    func getMyBookstopChallenges(in bookstop:Bookstop,page:Int = 1,per_page:Int = 10) -> Observable<Challenges> {
        return network.getData("user/gat_up/challenges?gatUpId=\(bookstop.id)&pageNum=\(page)&pageSize=\(per_page)&statusFilter=\(StatusFiler.notComplete.rawValue)")
    }
}
