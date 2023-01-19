import SwiftyJSON

public class ChallengeSummary {
    var challengeId: Int = 0
    var totalJoiner: Int = 0
    var totalObject: Int = 0
    
    init(fromJson json: JSON?) {
        challengeId = json?["challengeId"].intValue ?? 0
        totalJoiner = json?["totalJoiner"].intValue ?? 0
        totalObject = json?["totalObject"].intValue ?? 0
    }
}

