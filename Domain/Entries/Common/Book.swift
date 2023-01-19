import SwiftyJSON

public class Book: BaseModel {
    var sharingCount: Int = 0
    var saving: Bool = false
    var imageId: String = ""
    var rateCount: Int = 0
    var reviewCount: Int = 0
    var author: String = ""
    var authorName: String = ""
    var borrowCount: Int = 0
    var editionId: Int = 0
    var title: String = ""
    var rateAvg: Float = 0.0
    var rowNumber: Int = 0
    var bookId: Int = 0
    var userRelation: UserRelation? = nil
    var summary: BookSummary? = nil
    var numberPage: Int = 0
    
    public required init(json: JSON?, isInit: Bool = false) {
        super.init(json: json)
        
        if isInit {
            sharingCount = json?["sharingCount"].intValue ?? 0
            saving = json?["saving"].boolValue ?? false
            imageId = json?["imageId"].stringValue ?? ""
            rateCount = json?["rateCount"].intValue ?? 0
            reviewCount = json?["reviewCount"].intValue ?? 0
            author = json?["authorName"].stringValue ?? ""
            authorName = json?["authorName"].string ?? ""
            borrowCount = json?["borrowCount"].intValue ?? 0
            editionId = json?["editionId"].intValue ?? 0
            title = json?["title"].stringValue ?? ""
            rateAvg = json?["rateAvg"].floatValue ?? 0.0
            rowNumber = json?["rowNumber"].intValue ?? 0
            bookId = json?["bookId"].intValue ?? 0
            if json != nil && json?["userRelation"] != JSON.null {
                userRelation = UserRelation(fromJson: json?["userRelation"])
            }
            summary = BookSummary(fromJson: json?["summary"])
            numberPage = json?["numberOfPage"].int ?? 0
        }
    }
    
    init() {
        super.init(json: nil)
    }
    
    override func parseJson() {
        sharingCount = body?["sharingCount"].intValue ?? 0
        saving = body?["saving"].boolValue ?? false
        imageId = body?["imageId"].stringValue ?? ""
        rateCount = body?["rateCount"].intValue ?? 0
        reviewCount = body?["reviewCount"].intValue ?? 0
        author = body?["author"].stringValue ?? ""
        authorName = body?["authorName"].stringValue ?? ""
        borrowCount = body?["borrowCount"].intValue ?? 0
        editionId = body?["editionId"].intValue ?? 0
        title = body?["title"].stringValue ?? ""
        rateAvg = body?["rateAvg"].floatValue ?? 0.0
        rowNumber = body?["rowNumber"].intValue ?? 0
        bookId = body?["bookId"].intValue ?? 0
        if self.body != nil && body?["userRelation"] != JSON.null {
            userRelation = UserRelation(fromJson: body?["userRelation"])
        }
        summary = BookSummary(fromJson: body?["summary"])
    }
}
