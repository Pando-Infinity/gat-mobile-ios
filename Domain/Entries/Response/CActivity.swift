import SwiftyJSON

public class CActivity: BaseModel {
    var id: Int = 0
    var typeId: Int = 0
    var challenge: Challenge? = nil
    var createDate: String = ""
    var cProgress: ChallengeProgress? = nil
    var referId: Int = 0
    var user: Profile? = nil
    var book: BookInfo?
    
    public required init(json: JSON?, isInit: Bool = false) {
        super.init(json: json!)
        if isInit {
            id = json?["activityId"].intValue ?? 0
            typeId = json?["activityTypeId"].intValue ?? 0
            challenge = Challenge(json: json?["challenge"], isInit: true)
            createDate = json?["createDate"].stringValue ?? ""
            cProgress = ChallengeProgress(fromJson: json?["progress"])
            referId = json?["referId"].intValue ?? 0
            let user = json?["user"]
            if let userId = user?["userId"].int, let name = user?["name"].string {
                self.user = .init()
                self.user?.id = userId
                self.user?.name = name
                self.user?.imageId = user?["imageId"].string ?? ""
            }
            let edition = json?["edition"]
            if let editionId = edition?["editionId"].int, let title = edition?["title"].string {
                self.book = .init()
                self.book?.editionId = editionId
                self.book?.title = title
                self.book?.imageId = edition?["imageId"].string ?? ""
            }
        }
    }
    
    override func parseJson() {
        id = body?["activityId"].intValue ?? 0
        typeId = body?["activityTypeId"].intValue ?? 0
        challenge = Challenge(json: body?["challenge"], isInit: true)
        createDate = body?["createDate"].stringValue ?? ""
        cProgress = ChallengeProgress(fromJson: body?["progress"])
        referId = body?["referId"].intValue ?? 0
        let user = body?["user"]
        if let userId = user?["userId"].int, let name = user?["name"].string {
            self.user = .init()
            self.user?.id = userId
            self.user?.name = name
            self.user?.imageId = user?["imageId"].string ?? ""
        }
        let edition = body?["edition"]
        if let editionId = edition?["editionId"].int, let title = edition?["title"].string {
            self.book = .init()
            self.book?.editionId = editionId
            self.book?.title = title
            self.book?.imageId = edition?["imageId"].string ?? ""
        }
    }
    
    init() {
        super.init(json: nil)
    }
}
