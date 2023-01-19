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

/** Lưu dữ liệu mỗi cuốn sách của user*/
class BookInstant: Object {
    /**Mã bookInstant*/
    @objc dynamic var id: Int = -1
    @objc dynamic var ownerId: Int = -1

    /**Mã sách (một sách có nhiều edition, một edition có nhiều instant)*/
    @objc dynamic var bookId: Int = -1
    /**Mã của edition tương ứng của cuốn sách*/
    @objc dynamic var editionId: Int = -1
    /**Mã của ảnh bìa*/
    @objc dynamic var bookCoverId: String = ""
    /**Tiêu đề sách*/
    @objc dynamic var bookTitle: String = ""
    /**Tên tác giá của quyển sách*/
    @objc dynamic var bookAuthorName: String = ""
    /**Số lượt rate*/
    @objc dynamic var bookRateCount: Int = -1
    /**Số lượt cho mượn sách thành công*/
    @objc dynamic var sharingCompletedCount: Int = 0
    /**Tổng điểm đánh giá dành cho cuốn sách*/
    @objc dynamic var bookRateScore: Float = -1.0
    /**Tổng lượng đánh giá cuốn sách của người dùng*/
    @objc dynamic var bookReviewTotal: Int = -1
    /**Ngày thêm sách vào hệ thống*/
    @objc dynamic var addDate: NSDate = NSDate()
    /**Ngày bắt đầu sharebook*/
    @objc dynamic var startShareDate: NSDate = NSDate()
    
    /**sharingStatus (0: Not sharing, 1: Sharing, 2: Borrowing, 3: Lost)*/
    @objc dynamic var sharingStatus: Int = -1
    @objc dynamic var borrowingRecordId: Int  = -1
    @objc dynamic var borrowerId: Int = -1
    @objc dynamic var borrowerName: String = ""
    
    /**Khoảng thời gian cho mượn sách*/
    @objc dynamic var borrowDuration: Int = -1
    
    /**0: Không xoá, 1: Xoá (Đánh dấu là xoá để trường hợp không xoá thành công trên server
     thì vẫn xoá trên client để lần sau có mạng vẫn xoá lại được)*/
    @objc dynamic var deleteFlag: Int = 0
    
    /*Cài đặt khoá chính cho bảng BookInstant*/
    override static func primaryKey() -> String? {
        return "id"
    }
    
    /**Trả về BookInstant từ JSON, nếu trong DB chưa lưu sẽ tạo mới, nếu đã lưu thì lấy bản cập nhật*/
    static func parseFrom(json: JSON) -> BookInstant? {
        guard let id = json["instanceId"].int else {
            return nil
        }
        if let bookInstant = try! Realm().object(ofType: BookInstant.self, forPrimaryKey: id) {
            try! Realm().safeWrite {
                if json["sharingCompletedCount"].exists(), let sharingCompletedCount = json["sharingCompletedCount"].int {
                    bookInstant.sharingCompletedCount = sharingCompletedCount
                }
                if json["rateCount"].exists(), let rateCount = json["rateCount"].int {
                    bookInstant.bookRateCount = rateCount
                }
                if json["rateAvg"].exists(), let rateAvg = json["rateAvg"].float {
                    bookInstant.bookRateScore = rateAvg
                }
                if json["reviewCount"].exists(), let reviewCount = json["reviewCount"].int {
                    bookInstant.bookReviewTotal = reviewCount
                }
                if json["bookId"].exists(), let bookId = json["bookId"].int {
                    bookInstant.bookId = bookId
                }
                if json["imageId"].exists(), let imageId = json["imageId"].string {
                    bookInstant.bookCoverId = imageId
                }
                if json["editionId"].exists(), let editionId = json["editionId"].int {
                    bookInstant.editionId = editionId
                }
                if json["sharingStatus"].exists(), let sharingStatus = json["sharingStatus"].int {
                    bookInstant.sharingStatus = sharingStatus
                }
                if json["title"].exists(), let title = json["title"].string {
                    bookInstant.bookTitle = title
                }
                if json["author"].exists(), let author = json["author"].string {
                    bookInstant.bookAuthorName = author
                }
                if json["userAddDate"].exists(), let addDate = json["userAddDate"].uInt {
                    bookInstant.addDate = NSDate(timeIntervalSince1970: TimeInterval(addDate/1000))
                }
                if json["startShareDate"].exists(), let startSharedDate = json["startShareDate"].uInt {
                    bookInstant.startShareDate = NSDate(timeIntervalSince1970: TimeInterval(startSharedDate/1000))
                }
                
                /*Tìm hoặc tạo mới Owner với Id trả về*/
                bookInstant.ownerId = json["userId"].int ?? -1
                
                /*Tìm hoặc tạo mới người mượn từ Id trả về*/
                if json["borrowingRecordId"].exists(), let borrowingRecordId = json["borrowingRecordId"].int {
                    bookInstant.borrowingRecordId = borrowingRecordId
                    bookInstant.borrowerId = json["borrowingUserId"].int ?? -1
                    bookInstant.borrowerName = json["borrowingUserName"].string ?? ""
                }

            }
            return bookInstant
        } else {
            let newBook = BookInstant()
            newBook.id = id
            newBook.sharingCompletedCount = json["sharingCompletedCount"].int ?? 0
            newBook.bookRateCount = json["rateCount"].int ?? -1
            newBook.bookRateScore = json["rateAvg"].float ?? 0.0
            newBook.bookReviewTotal = json["reviewCount"].int ?? -1
            newBook.bookId = json["bookId"].int ?? -1
            newBook.bookCoverId = json["imageId"].string ?? "33070404441"
            newBook.bookTitle = json["title"].string ?? ""
            newBook.editionId = json["editionId"].int ?? -1
            newBook.sharingStatus = json["sharingStatus"].int ?? -1
            newBook.bookAuthorName = json["author"].string ?? ""
            
            if let addDate = json["userAddDate"].int64 {
                newBook.addDate = NSDate(timeIntervalSince1970: TimeInterval(addDate/1000))
            }
            
            if let startSharedDate = json["startShareDate"].int64 {
                newBook.startShareDate = NSDate(timeIntervalSince1970: TimeInterval(startSharedDate/1000))
            }
            
            /*Tìm hoặc tạo mới Owner với Id trả về*/
            newBook.ownerId = json["userId"].int ?? -1
            
//            Tìm hoặc tạo mới người mượn từ Id trả về
            if let borrowingRecordId = json["borrowingRecordId"].int {
                newBook.borrowingRecordId = borrowingRecordId
                newBook.borrowerId = json["borrowingUserId"].int ?? -1
                newBook.borrowerName = json["borrowingUserName"].string ?? ""
            }
            
            return newBook
        }
    }
}
