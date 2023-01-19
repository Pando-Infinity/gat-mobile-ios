import SwiftyJSON

public class Readings: BaseModel {
    var readings: [Reading]? = nil
    var page: Int = 0
    var pageSize: Int = 0
    var total: Int = 0
    
    override func parseJson() {
        readings = body?["pageData"].arrayValue.map { Reading(json: $0, isInit: true) } ?? []
        page = body?["pageNo"].intValue ?? 0
        pageSize = body?["pageSize"].intValue ?? 0
        total = body?["total"].intValue ?? 0
    }
}
