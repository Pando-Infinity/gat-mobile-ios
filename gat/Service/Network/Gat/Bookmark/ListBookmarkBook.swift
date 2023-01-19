import Foundation
import Alamofire
import SwiftyJSON

class ListBookBookmarkRequest: APIRequest {
    var path: String { return "bookmark/book/self_get_bookmark" }
    
    var method: HTTPMethod { return .post }
    
    var parameters: Parameters? {
        var params: [String: Any] = ["page": self.page, "perPage": self.per_page]
        if !self.keyword.isEmpty {
            params["keyword"] = self.keyword
        }
        return params
    }
    
    var encoding: ParameterEncoding { return JSONEncoding.default }
    
    fileprivate let keyword: String
    fileprivate let page: Int
    fileprivate let per_page: Int
    
    init(keyword: String, page: Int, per_page: Int) {
        self.keyword = keyword
        self.page = page
        self.per_page = per_page
    }
}

class TotalListBookBookmarkRequest: APIRequest {
    var path: String { return "bookmark/book/self_get_bookmark_total" }
}

class ListBookBookmarkResponse: APIResponse {
    typealias Resource = [BookInfo]
    
    func map(data: Data?, statusCode: Int) -> [BookInfo]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"].array?.compactMap({ (item) -> BookInfo? in
            let edition = item["edition"]
            let book = BookInfo()
            book.editionId = edition["editionId"].int ?? 0
            book.bookId = edition["bookId"].int ?? 0
            book.isbn10 = edition["isbn10"].string ?? ""
            book.isbn13 = edition["isbn13"].string ?? ""
            book.title = edition["title"].string ?? ""
            book.imageId = edition["imageId"].string ?? ""
            book.descriptionBook = edition["description"].string ?? ""
            book.rateAvg = item["rateAvg"].double ?? 0.0
            book.author = edition["author"].string ?? ""
            return book
        })
    }
}
