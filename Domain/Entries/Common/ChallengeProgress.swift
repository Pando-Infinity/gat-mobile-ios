import SwiftyJSON

public class ChallengeProgress {
    var id: Int = 0
    var targetNumber: Int = 0
    var progress: Int = 0
    var joinDate: String = ""
    
    init(fromJson json: JSON?) {
        id = json?["challengeId"].intValue ?? 0
        targetNumber = json?["targetNumber"].intValue ?? 0
        progress = json?["progress"].intValue ?? 0
        joinDate = json?["joinDate"].stringValue ?? ""
    }
}
