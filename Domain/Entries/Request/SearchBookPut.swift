import SwiftyJSON

public class SearchBookPut {
    var title: String = ""
    var pageNum: Int = 0
    var pageSize: Int = 0
    
    init(title: String, pageNum: Int, pageSize: Int) {
        self.title = title
        self.pageNum = pageNum
        self.pageSize = pageSize
    }
    
    func toJSON() -> Dictionary<String, Any> {
        return [
            "criteria": ["languagesPriority": [1, 2], "title": self.title],
            "pageNum": self.pageNum,
            "pageSize": self.pageSize
        ]
    }
}

