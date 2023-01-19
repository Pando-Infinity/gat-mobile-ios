import Foundation

// Fired when user click to cell challenge to open Challenge detail
// ListChallengeVC handle this event to open Challenge Detail
struct OpenChallengeDetailEvent {
    static let EVENT_NAME = "OpenChallengeDetailEvent"
    
    var challengeId: Int = 0
    
    init(_ challengeId: Int) {
        self.challengeId = challengeId
    }
}
