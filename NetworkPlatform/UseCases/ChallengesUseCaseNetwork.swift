import Foundation
import RxSwift

final class ChallengesUseCaseNetwork: ChallengesUseCase {
    private let network: ChallengesNetwork
    
    init(network: ChallengesNetwork) {
        self.network = network
    }
    
    func getChallenges() -> Observable<Challenges> {
        return network.getChallenges()
    }
    
    func getMyChallenges() -> Observable<Challenges> {
        return network.getMyChallenge()
    }
    
    func getBookstopChallenges(in bookstop:Bookstop) -> Observable<Challenges> {
        return network.getBookstopChallenges(in: bookstop)
    }
    
    func getMyBookstopChallenges(in bookstop:Bookstop) -> Observable<Challenges> {
        return network.getMyBookstopChallenges(in: bookstop)
    }
    
}
