import Foundation
import Alamofire
import SwiftyJSON

class ListBookUpdateRequest: APIRequest {
    var path: String { return "bookdata/self/get_missing_book" }
    
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

class TotalListBookWaitingRequest: APIRequest {
    var path: String { return "bookdata/self/get_waiting_book_total" }
}

class ListBookUpdateResponse: APIResponse {
    typealias Resource = [BookUpdate]
    
    func map(data: Data?, statusCode: Int) -> [BookUpdate]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"].array?.compactMap({ (item) -> BookUpdate? in
            let book = BookUpdate()
            book.waitingId = item["waitingId"].int ?? 0
            book.title = item["title"].string ?? ""
            book.note = item["note"].string ?? ""
            book.waiting = item["waiting"].bool ?? true
            book.createDate = Date(timeIntervalSince1970: (item["createDate"].double ?? 0.0) / 1000.0)
            book.updateDate = Date(timeIntervalSince1970: (item["updateDate"].double ?? 0.0) / 1000.0)
            return book
        })
    }
}
