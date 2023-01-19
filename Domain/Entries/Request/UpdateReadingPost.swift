import SwiftyJSON

public class UpdateReadingPost {
    private var editionId: Int?
    private var pageNum: Int
    private var readPage: Int
    private var readingId: Int?
    private var readingStatusId: Int = 1
    private var startDate: String = ""
    private var completeDate: String = ""
    
    init(
        //completeDate: Date?,
        editionId: Int?,
        pageNum: Int,
        readPage: Int,
        readingId: Int?,
        readingStatusId: Int,
        startDate: String,
        completeDate: String
    ) {
        //self.completeDate = completeDate
        self.editionId = editionId
        self.pageNum = pageNum
        self.readPage = readPage
        self.readingId = readingId
        self.readingStatusId = readingStatusId
        self.startDate = startDate
        self.completeDate = completeDate
    }
    
    func toJSON() -> Dictionary<String, Any> {
        return [
            "editionId": self.editionId,
            "pageNum": self.pageNum,
            "readPage": self.readPage,
            "readingId": self.readingId,
            "readingStatusId": self.readingStatusId,
            "startDate": self.startDate,
            "completeDate": self.completeDate
        ]
    }
}
