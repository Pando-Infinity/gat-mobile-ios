import SwiftyJSON

public class Reading: BaseModel {
    var readingId: Int = 0
    var userId: Int = 0
    var edition: Book? = nil
    var readingStatusId: Int = 0
    var followDate: String = ""
    var startDate: String = ""
    var completeDate: String = ""
    var pageNum: Int = 0
    var readPage: Int = 0
    var progress: Float = 0.0
    
    public required init(json: JSON?, isInit: Bool = false) {
        super.init(json: json)
        
        if isInit {
            readingId = json?["readingId"].intValue ?? 0
            userId = json?["userId"].intValue ?? 0
            edition = Book(json: json?["edition"], isInit: true)
            readingStatusId = json?["readingStatusId"].intValue ?? 0
            followDate = json?["followDate"].stringValue ?? ""
            startDate = json?["startDate"].stringValue ?? ""
            completeDate = json?["completeDate"].stringValue ?? ""
            pageNum = json?["pageNum"].intValue ?? 0
            readPage = json?["readPage"].intValue ?? 0
            calProcess()
        }
    }
    
    init() {
        super.init(json: nil)
    }
    
    override func parseJson() {
        readingId = body?["readingId"].intValue ?? 0
        userId = body?["userId"].intValue ?? 0
        edition = Book(json: body?["edition"], isInit: true)
        readingStatusId = body?["readingStatusId"].intValue ?? 0
        followDate = body?["followDate"].stringValue ?? ""
        startDate = body?["startDate"].stringValue ?? ""
        completeDate = body?["completeDate"].stringValue ?? ""
        pageNum = body?["pageNum"].intValue ?? 0
        readPage = body?["readPage"].intValue ?? 0
        calProcess()
    }
    
    private func calProcess() {
        if pageNum > 0 {
            progress = Float(readPage) / Float(pageNum)
        }
    }
}

extension Reading {
    enum ReadingStatus: Int {
        case all = -1 // Case all status
        case read = 0 // Case book read complete
        case reading = 1 // Case book is reading
    }
}
