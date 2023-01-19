import Foundation

// Fired when user click to icon follow or unFollow member in screen List Active Members
// ActiveMemberVC handle this event to call API follow or unFollow member
struct FollowMemberEvent {
    static let EVENT_NAME: String = "FollowMemberEvent"
    
    var userId: Int = 0
    var userName: String = ""
    // If isFollow = true that means user is have in list my following
    // and then we should remove this member from list my following
    // If isFollow = false means user not have in list my following yet
    // and then we should add this member from list my following
    var isFollow: Bool = true
    
    init(_ userId: Int, _ userName: String, _ isFollow: Bool) {
        self.userId = userId
        self.userName = userName
        self.isFollow = isFollow
    }
}
