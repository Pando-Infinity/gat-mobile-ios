import Foundation

// Fired when user click to view creator in ChallengeContentCell
// ChallengeDetailVC handle it to show profile of Creator
struct OpenProfileEvent {
    static let EVENT_NAME: String = "OpenProfileEvent"
    
    var userPublic: UserPublic?
    
    init(_ userPublic: UserPublic) {
        self.userPublic = userPublic
    }
}
