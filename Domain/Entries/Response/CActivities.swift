import SwiftyJSON

public class CActivities: BaseModel {
    var activities: [CActivity]? = nil
    var page: Int = 0
    var pageSize: Int = 0
    var total: Int = 0
    
    override func parseJson() {
        print(self.body)
        activities = body?["pageData"].arrayValue.map { CActivity(json: $0, isInit: true) } ?? []
        page = body?["pageNo"].intValue ?? 0
        pageSize = body?["pageSize"].intValue ?? 0
        total = body?["total"].intValue ?? 0
    }
}
