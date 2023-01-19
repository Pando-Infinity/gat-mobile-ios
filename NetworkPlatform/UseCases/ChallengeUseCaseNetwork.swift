import Foundation
import RxSwift

final class ChallengeUseCaseNetwork: ChallengeUseCase {
    private let network: ChallengeNetwork
    
    init(network: ChallengeNetwork) {
        self.network = network
    }
    
    func getChallenge(id: Int) -> Observable<Challenge> {
        return network.getChallenge(id: id)
    }
}
