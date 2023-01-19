import Foundation
import RxSwift

public protocol ChallengesUseCase {
    
    func getChallenges() -> Observable<Challenges>
    
    func getMyChallenges() -> Observable<Challenges>
    
    func getBookstopChallenges(in bookstop: Bookstop) -> Observable<Challenges>
    
    func getMyBookstopChallenges(in bookstop: Bookstop) -> Observable<Challenges>
}
