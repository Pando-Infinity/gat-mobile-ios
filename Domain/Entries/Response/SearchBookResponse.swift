import SwiftyJSON

public class SearchBookResponse: BaseModel {
    var books: [Book]? = nil
    
    override func parseJson() {
        books = body?["pageData"].arrayValue.map { Book(json: $0, isInit: true) } ?? []
    }
}
