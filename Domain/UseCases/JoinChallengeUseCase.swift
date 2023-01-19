import Foundation
import RxSwift

public protocol JoinChallengeUseCase {
    func joinChallenge(challengeId: Int, targetNumber: Int) -> Observable<BaseModel>
}
