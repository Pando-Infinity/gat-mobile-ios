//
//  Review.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

public class Review: BaseModel {
    var reviewId: Int = 0
    var userId: Int = 0
    var bookId: Int = 0
    var editionId: Int = 0
    var user: Profile?
    var book: BookInfo?
    var reviewType: Int = 0
    var value: Double = 0.0
    var review: String = ""
    var intro: String = ""
    var draftFlag: Bool = false
    var saving: Bool = false
    var evaluationTime: Date = Date()
    
    /*(Đánh dấu là xoá để trường hợp không xoá thành công trên server
     thì vẫn xoá trên client để lần sau có mạng vẫn xoá lại được)
     */
    var deleteFlag: Bool = false
    
    init() {
        super.init(json: nil)
        self.user = Profile()
        self.book = BookInfo()
    }
    
    required public init(json: JSON?, isInit: Bool = false) {
        super.init(json: json)
    }
    
    override func parseJson() {
        let result = body?["resultInfo"]
        reviewId = result?["evaluationId"].intValue ?? 0
        userId = result?["userId"].intValue ?? 0
        bookId = result?["bookId"].intValue ?? 0
        editionId = result?["editionId"].intValue ?? 0
        reviewType = result?["reviewType"].intValue ?? 0
        intro = result?["intro"].stringValue ?? ""
        value = result?["value"].doubleValue ?? 0.0
        review = result?["review"].stringValue ?? ""
        draftFlag = result?["draftFlag"].boolValue ?? false
        if let evaluationTime = result?["evaluationTime"].double {
            self.evaluationTime = Date(timeIntervalSince1970: evaluationTime / 1000.0)
        }
//        evaluationTime = .init(timeIntervalSince1970: (result?["evaluationTime"].double ?? 0.0) / 1000.0)
    }
}

extension Review: ObjectConvertable {
    typealias Object = ReviewObject
    
    func asObject() -> ReviewObject {
        let object = ReviewObject()
        object.reviewId = self.reviewId
        object.user = self.user?.asObject()
        object.book = self.book?.asObject()
        object.value = self.value
        object.intro = self.intro
        object.review = self.review
        object.draftFlag = self.draftFlag
        object.saving = self.saving
        object.evaluationTime = self.evaluationTime
        object.deleteFlag = self.deleteFlag
        object.reviewType = self.reviewType
        return object
    }
    
}

class ReviewObject: Object {
    @objc dynamic var reviewId: Int = 0
    @objc dynamic var user: ProfileObject?
    @objc dynamic var book: BookInfoObject?
    @objc dynamic var reviewType: Int = 0
    @objc dynamic var value: Double = 0.0
    @objc dynamic var review: String = ""
    @objc dynamic var intro: String = ""
    @objc dynamic var draftFlag: Bool = false
    @objc dynamic var saving: Bool = false
    @objc dynamic var evaluationTime: Date = Date()
    
    @objc dynamic var deleteFlag: Bool = false
    
    override class func primaryKey() -> String? {
        return "reviewId"
    }
}

extension ReviewObject: DomainConvertable {
    typealias Domain = Review
    
    func asDomain() -> Review {
        let domain = Review()
        domain.reviewId = self.reviewId
        domain.user = self.user?.asDomain()
        domain.book = self.book?.asDomain()
        domain.value = self.value
        domain.intro = self.intro
        domain.review = self.review
        domain.draftFlag = self.draftFlag
        domain.saving = self.saving
        domain.evaluationTime = self.evaluationTime
        domain.deleteFlag = self.deleteFlag
        domain.reviewType = self.reviewType
        return domain
    }
    
    
}

extension ReviewObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        return self.reviewId
    }
}
