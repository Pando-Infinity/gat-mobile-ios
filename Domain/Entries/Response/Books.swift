import SwiftyJSON

public class Books: BaseModel {
    var books: [Book]? = nil
    
    override func parseJson() {
        books = body?["pageData"].arrayValue.map { Book(json: $0, isInit: true) } ?? []
    }
}
