import Foundation
import RxSwift

public protocol ChallengeUseCase {
    
    func getChallenge(id: Int) -> Observable<Challenge>
}
