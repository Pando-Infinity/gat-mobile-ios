import Foundation

// Fired when user click to see all member or list friend members
// in ChallengeContentCell
// ChallengeDetailVC handle this event to open screen Challenge members
struct OpenChallengeMembersEvent {
    static let EVENT_NAME = "OpenChallengeMembersEvent"
    
    var isOpenFollowTab: Bool = false
    
    init(_ isOpenFollowTab: Bool) {
        self.isOpenFollowTab = isOpenFollowTab
    }
}
