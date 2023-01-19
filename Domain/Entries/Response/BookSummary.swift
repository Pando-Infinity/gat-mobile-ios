import SwiftyJSON

public class BookSummary {
    var readingCount: Int = 0
    
    init(fromJson json: JSON?) {
        readingCount = json?["readingCount"].intValue ?? 0
    }
}
