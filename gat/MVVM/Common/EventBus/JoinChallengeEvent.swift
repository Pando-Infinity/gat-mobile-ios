import Foundation

// Fired when user click Join Challenge in JoinChallengeVC
// ChallengeDetailVC handle this event to call API join Challenge
struct JoinChallengeEvent {
    static let EVENT_NAME: String = "JoinChallengeEvent"
    
    var targetNumber: Int = 0
    
    init(_ targetNumber: Int) {
        self.targetNumber = targetNumber
    }
}
