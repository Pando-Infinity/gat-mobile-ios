import SwiftyJSON

public class UserRelation {
    var readingId: Int = -1
    var readingStatusId: Int = 1
    var followDate: String = ""
    var startDate: String = ""
    var completeDate: String = ""
    var pageNum: Int = 0
    var readPage: Int = 0
    var progress: Float = 0.0
    var isReadingNull: Bool = true
    var instanceCount: Int = 0
    
    init(fromJson json: JSON?) {
        instanceCount = json?["instanceCount"].intValue ?? 0
        
        let reading: JSON? = json?["reading"]
        if let it = reading, let readingId = it["readingId"].int {
            self.readingId = readingId
            readingStatusId = it["readingStatusId"].intValue
            followDate = it["followDate"].stringValue
            startDate = it["startDate"].stringValue
            completeDate = it["completeDate"].stringValue
            pageNum = it["pageNum"].intValue
            readPage = it["readPage"].intValue
            calProcess()
        }
        
        if (readingId > 0) {
            isReadingNull = false
        }
        
        print("json Reading: \(reading), instanceCount: \(instanceCount)")
    }
    
    init() {
    }
    
    private func calProcess() {
        if pageNum > 0 {
            progress = Float(readPage) / Float(pageNum)
        }
    }
}
