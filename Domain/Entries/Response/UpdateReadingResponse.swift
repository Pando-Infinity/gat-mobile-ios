import SwiftyJSON

public class UpdateReadingResponse: BaseModel {
    var completeDate: String = ""
    var followDate: String = ""
    var pageNum: Int = 0
    var readPage: Int = 0
    var readingId: Int = 0
    var readingStatusId: Int = 0
    var startDate: String = ""
    var userId: Int = 0
    
    override func parseJson() {
        completeDate = body?["completeDate"].stringValue ?? ""
        followDate = body?["followDate"].stringValue ?? ""
        pageNum = body?["pageNum"].intValue ?? 0
        readPage = body?["readPage"].intValue ?? 0
        readingId = body?["readingId"].intValue ?? 0
        readingStatusId = body?["readingStatusId"].intValue ?? 0
        startDate = body?["startDate"].stringValue ?? ""
        userId = body?["userId"].intValue ?? 0
    }
}
