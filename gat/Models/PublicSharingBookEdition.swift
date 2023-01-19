//
//  BookInstant.swift
//  gat
//
//  Created by HungTran on 3/15/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

class PublicSharingBookEdition: Object {
    /**Mã bookEdition*/
    @objc dynamic var id: Int = -1
    @objc dynamic var user: User? = nil
    
    /**Mã sách (một sách có nhiều edition, một edition có nhiều instant)*/
    @objc dynamic var bookId: Int = -1
    /**Mã của ảnh bìa*/
    @objc dynamic var imageId: String = ""
    /**Tiêu đề sách*/
    @objc dynamic var title: String = ""
    /**Tên tác giá của quyển sách*/
    @objc dynamic var author: String = ""
    /**Số lượt rate*/
    @objc dynamic var rateCount: Int = -1
    /**Số lượt cho mượn sách thành công*/
    @objc dynamic var sharingCount: Int = 0
    /**Tổng điểm đánh giá dành cho cuốn sách*/
    @objc dynamic var rateAvg: Float = -1.0
    /**Tổng lượng đánh giá cuốn sách của người dùng*/
    @objc dynamic var reviewCount: Int = -1
    
    /**Trường này nhận 2 giá trị: 0, 1
     0 => Sách không còn Available, sách đã được mượn
     1 => Sách đang available, chưa ai ai mượn*/
    @objc dynamic var availbleStatus: Int = -1
    
    /**Trường này nhận 2 giá trị: 0, 1
     0 => Hiện người dùng đang login chưa gửi yêu cầu tới sách
     1 => Ngược lại*/
    @objc dynamic var requestingStatus: Int = -1
    @objc dynamic var recordId: Int = -1
    
    /**recordStatus = 0: Đợi đồng ý
     recordStatus = 1: Đợi đến lượt
     recordStatus = 2: Đang liên lạc
     recordStatus = 3: Đang mượn*/
    @objc dynamic var recordStatus: Int = -1
    
    /*Cài đặt khoá chính cho bảng BookInstant*/
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func parseFrom(json: JSON) -> PublicSharingBookEdition? {
        guard let id = json["editionId"].int else {
            return nil
        }
        
        if let bookEdition = try! Realm().object(ofType: PublicSharingBookEdition.self, forPrimaryKey: id) {
            try! Realm().safeWrite {
                if json["bookId"].exists(), let bookId = json["bookId"].int {
                    bookEdition.bookId = bookId
                }
                if json["title"].exists(), let title = json["title"].string {
                    bookEdition.title = title
                }
                if json["imageId"].exists(), let imageId = json["imageId"].string {
                    bookEdition.imageId = imageId
                }
                if json["rateAvg"].exists(), let rateAvg = json["rateAvg"].float {
                    bookEdition.rateAvg = rateAvg
                }
                if json["rateCount"].exists(), let rateCount = json["rateCount"].int {
                    bookEdition.rateCount = rateCount
                }
                if json["reviewCount"].exists(), let reviewCount = json["reviewCount"].int {
                    bookEdition.reviewCount = reviewCount
                }
                if json["author"].exists(), let author = json["author"].string {
                    bookEdition.author = author
                }
                if json["sharingCount"].exists(), let sharingCount = json["sharingCount"].int {
                    bookEdition.sharingCount = sharingCount
                }
                if json["availableStatus"].exists(), let availbleStatus = json["availableStatus"].int {
                    bookEdition.availbleStatus = availbleStatus
                }
                if json["requestingStatus"].exists(), let requestingStatus = json["requestingStatus"].int {
                    bookEdition.requestingStatus = requestingStatus
                }
                if json["recordId"].exists(), let recordId = json["recordId"].int {
                    bookEdition.recordId = recordId
                }
                if json["recordStatus"].exists(), let recordStatus = json["recordStatus"].int {
                    bookEdition.recordStatus = recordStatus
                }
                bookEdition.user = User.parseFrom(json: ["userId": json["userId"]])
            }
            return bookEdition
        } else {
            let bookEdition = PublicSharingBookEdition()
            bookEdition.id = id
            bookEdition.user = User.parseFrom(json: ["userId": json["userId"]])
            bookEdition.bookId = json["bookId"].int ?? -1
            bookEdition.title = json["title"].string ?? ""
            bookEdition.imageId = json["imageId"].string ?? ""
            bookEdition.rateAvg = json["rateAvg"].float ?? 0.0
            bookEdition.rateCount = json["rateCount"].int ?? 0
            bookEdition.reviewCount = json["reviewCount"].int ?? 0
            bookEdition.author = json["author"].string ?? ""
            bookEdition.sharingCount = json["sharingCount"].int ?? 0
            bookEdition.availbleStatus = json["availableStatus"].int ?? 0
            bookEdition.requestingStatus = json["requestingStatus"].int ?? 0
            bookEdition.recordId = json["recordId"].int ?? 0
            bookEdition.recordStatus = json["recordStatus"].int ?? 0
            return bookEdition
        }
    }
}
