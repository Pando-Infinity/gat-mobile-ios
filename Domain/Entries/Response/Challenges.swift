import SwiftyJSON

public class Challenges: BaseModel {
    var challenges: [Challenge]? = nil
    var page: Int = 0
    var pageSize: Int = 0
    var total: Int = 0
    
    override func parseJson() {
        challenges = body?["pageData"].arrayValue.map { Challenge(json: $0, isInit: true) } ?? []
        page = body?["pageNo"].intValue ?? 0
        pageSize = body?["pageSize"].intValue ?? 0
        total = body?["total"].intValue ?? 0
    }
}
