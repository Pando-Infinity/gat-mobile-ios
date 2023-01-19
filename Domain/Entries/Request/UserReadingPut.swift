import SwiftyJSON

public class UserReadingPut {
    var readingStatus: Reading.ReadingStatus
    var pageNum: Int = 0
    var pageSize: Int = 0
    
    init(readingStatus: Reading.ReadingStatus = .all, pageNum: Int, pageSize: Int) {
        self.readingStatus = readingStatus
        self.pageNum = pageNum
        self.pageSize = pageSize
    }
    
    func toJSON() -> Dictionary<String, Any> {
        var status = ""
        if self.readingStatus != .all {
            status = String(self.readingStatus.rawValue)
        }
        return [
            "criteria": ["readingStatus": status],
            "pageNum": self.pageNum,
            "pageSize": self.pageSize,
            "sorts": [
                "updateDate": "DESC"
            ]
        ]
    }
}
