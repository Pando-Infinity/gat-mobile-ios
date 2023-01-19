import Foundation
import RxSwift

final class JoinChallengeUseCaseNetwork: JoinChallengeUseCase {
    private let network: JoinChallengeNetwork
    
    init(network: JoinChallengeNetwork) {
        self.network = network
    }
    
    func joinChallenge(challengeId: Int, targetNumber: Int) -> Observable<BaseModel> {
        return network.joinChallenge(id: challengeId, targetNumber: targetNumber)
    }
}
