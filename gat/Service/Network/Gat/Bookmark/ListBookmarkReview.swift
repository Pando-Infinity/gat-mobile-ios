import Foundation
import Alamofire
import SwiftyJSON

class ListReviewBookmarkRequest: APIRequest {
    var path: String { return "bookmark/review/self_get_bookmark" }
    
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

class TotalListReviewBookmarkRequest: APIRequest {
    var path: String { return "bookmark/review/self_get_bookmark_total" }
}

class ListReviewBookmarkResponse: APIResponse {
    typealias Resource = [Review]
    
    func map(data: Data?, statusCode: Int) -> [Review]? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        return json["data"]["pageData"].array?.compactMap({ (item) -> Review? in
            let r = item["review"]
            let review = Review()
            review.reviewId = r["reviewId"].int ?? 0
            review.reviewType = r["reviewType"].int ?? 0
            review.intro = r["intro"].string ?? ""
            review.value = r["value"].double ?? 0.0
            review.review = r["review"].string ?? ""
            review.draftFlag = r["draftFlag"].bool ?? false
            review.evaluationTime = Date(timeIntervalSince1970: (r["evaluationTime"].double ?? 0.0) / 1000.0)
            review.book = BookInfo()
            review.book?.editionId = r["edition"]["editionId"].int ?? 0
            review.book?.bookId = r["edition"]["bookId"].int ?? 0
            review.book?.title = r["edition"]["title"].string ?? ""
            review.book?.imageId = r["edition"]["imageId"].string ?? ""
            review.book?.author = r["edition"]["author"].string ?? ""
            review.user = Profile()
            review.user?.id = r["user"]["userId"].int ?? 0
            review.user?.name = r["user"]["name"].string ?? ""
            review.user?.imageId = r["user"]["imageId"].string ?? ""
            review.user?.address = r["user"]["address"].string ?? ""
            review.user?.about = r["user"]["about"].string ?? ""
            review.user?.userTypeFlag = UserType(rawValue: r["user"]["userTypeFlag"].int ?? 0) ?? .normal
            return review
        })
    }
    
}
