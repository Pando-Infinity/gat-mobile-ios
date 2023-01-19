import Foundation

struct UpdateChallengeCellHeightEvent {
    static let EVENT_NAME = "UpdateChallengeCellHeightEvent"
    
    var isExpand: Bool
    
    init(_ isExpand: Bool) {
        self.isExpand = isExpand
    }
}
