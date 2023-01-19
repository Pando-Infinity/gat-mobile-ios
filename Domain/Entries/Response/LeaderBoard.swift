import SwiftyJSON

public class LeaderBoard: BaseModel {
    var challengeId: Int =  0
    var targetNumber: Int = 0
    var progress: Int = 0
    var joinDate: String = ""
    var isFollowing: Bool = false
    var user: Profile? = nil
    
    public required init(json: JSON?, isInit: Bool = false) {
        super.init(json: json!, isInit: isInit)
        if isInit {
            challengeId = json?["challengeId"].intValue ?? 0
            targetNumber = json?["targetNumber"].intValue ?? 0
            progress = json?["progress"].intValue ?? 0
            joinDate = json?["joinDate"].stringValue ?? ""
            isFollowing = json?["following"].boolValue ?? false
            let user = json?["user"]
            if let userId = user?["userId"].int, let name = user?["name"].string {
                self.user = Profile()
                self.user?.id = userId
                self.user?.name = name
                self.user?.about = user?["about"].string ?? ""
                self.user?.address = user?["address"].string ?? ""
                self.user?.imageId = user?["imageId"].string ?? ""
                self.user?.coverImageId = user?["coverImageId"].string ?? ""
                if let latitude = user?["latitude"].double, let longitude = user?["longitude"].double {
                    self.user?.location = .init(latitude: latitude, longitude: longitude)
                }
                self.user?.userTypeFlag = UserType(rawValue: user?["userTypeFlag"].int ?? 1) ?? .normal
                
            }
        }
    }
    
    init() {
        super.init(json: nil)
    }
}
