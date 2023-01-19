import SwiftyJSON

public class LeaderBoards: BaseModel {
    var leaderBoards: [LeaderBoard]? = nil
    var page: Int = 0
    var pageSize: Int = 0
    var total: Int = 0
    
    override func parseJson() {
        leaderBoards = body?["pageData"].arrayValue.map { LeaderBoard(json: $0, isInit: true) } ?? []
        page = body?["pageNo"].intValue ?? 0
        pageSize = body?["pageSize"].intValue ?? 0
        total = body?["total"].intValue ?? 0
    }
}
