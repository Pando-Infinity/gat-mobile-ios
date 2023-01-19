//
//  ReadingBookInstant.swift
//  gat
//
//  Created by HungTran on 4/2/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

/** Lưu dữ liệu mỗi cuốn sách mà User đang đọc*/
class ReadingBookInstant: Object {
    /**Mã ID của Reading*/
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
    /**Tổng điểm đánh giá dành cho cuốn sách*/
    @objc dynamic var bookRateScore: Float = -1.0
    /**Ngày thêm sách vào hệ thống*/
    @objc dynamic var followDate: NSDate = NSDate()
    /**Ngày bắt đầu sharebook*/
    @objc dynamic var startDate: NSDate = NSDate()
    /**Ngày bắt đầu sharebook*/
    @objc dynamic var completeDate: NSDate = NSDate()
    
    /**readingStatus 0: Đã đọc 1: Đang đọc 2: Sẽ đọc*/
    @objc dynamic var readingStatus: Int = -1
    @objc dynamic var borrowRecordId: Int = -1
    @objc dynamic var lenderId: Int = -1
    @objc dynamic var lenderName: String = ""
    
    /**0: Không xoá, 1: Xoá (Đánh dấu là xoá để trường hợp không xoá thành công trên server
     thì vẫn xoá trên client để lần sau có mạng vẫn xoá lại được)*/
    @objc dynamic var deleteFlag: Int = 0
    
    /**Cài đặt khoá chính cho bảng BookInstant*/
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func parseFrom(json: JSON) -> ReadingBookInstant? {
        guard let id = json["readingId"].int else {
            return nil
        }
        if let newBook = try! Realm().object(ofType: ReadingBookInstant.self, forPrimaryKey: id) {
            try! Realm().safeWrite {
                if json["rateAvg"].exists(), let rateAvg = json["rateAvg"].float {
                    newBook.bookRateScore = rateAvg
                }
                if json["bookId"].exists(), let bookId = json["bookId"].int {
                    newBook.bookId = bookId
                }
                if json["editionId"].exists(), let editionId = json["editionId"].int {
                    newBook.editionId = editionId
                }
                if json["editionImageId"].exists(), let editionImageId = json["editionImageId"].string {
                    newBook.bookCoverId = editionImageId
                }
                if json["title"].exists(), let title = json["title"].string {
                    newBook.bookTitle = title
                }
                
                if let startDate = json["startDate"].int64 {
                    newBook.startDate = NSDate(timeIntervalSince1970: TimeInterval(startDate/1000))
                }
                
                if let followDate = json["followDate"].int64 {
                    newBook.followDate = NSDate(timeIntervalSince1970: TimeInterval(followDate/1000))
                }
                
                if let completeDate = json["completeDate"].int64 {
                    newBook.completeDate = NSDate(timeIntervalSince1970: TimeInterval(completeDate/1000))
                }
                
                /*Tìm hoặc tạo mới Owner với Id trả về*/
                newBook.ownerId = json["userId"].int ?? -1
                
                newBook.readingStatus = json["readingStatus"].int ?? -1
                newBook.bookAuthorName = json["author"].string ?? ""
                
                /*Tìm hoặc tạo mới người mượn từ Id trả về*/
                if let borrowRecordId = json["borrowRecordId"].int {
                    newBook.borrowRecordId = borrowRecordId
                    newBook.lenderId = json["borrowFromUserId"].int ?? -1
                    newBook.lenderName = json["borrowFromUserName"].string ?? ""
                }
            }
            return newBook
        }
        
        let newBook = ReadingBookInstant()
        /*Xử lý dữ liệu trả về tại dây*/
        newBook.id = id
        
        newBook.bookRateScore = json["rateAvg"].float ?? 0.0
        newBook.bookId = json["bookId"].int ?? -1
        newBook.editionId = json["editionId"].int ?? -1
        newBook.bookCoverId = json["editionImageId"].string ?? ""
        newBook.bookTitle = json["title"].string ?? ""
        newBook.editionId = json["editionId"].int ?? -1
        
        if let startDate = json["startDate"].int64 {
            newBook.startDate = NSDate(timeIntervalSince1970: TimeInterval(startDate/1000))
        }
        
        if let followDate = json["followDate"].int64 {
            newBook.followDate = NSDate(timeIntervalSince1970: TimeInterval(followDate/1000))
        }
        
        if let completeDate = json["completeDate"].int64 {
            newBook.completeDate = NSDate(timeIntervalSince1970: TimeInterval(completeDate/1000))
        }
        
        /*Tìm hoặc tạo mới Owner với Id trả về*/
        newBook.ownerId = json["userId"].int ?? -1
        
        newBook.readingStatus = json["readingStatus"].int ?? -1
        newBook.bookAuthorName = json["author"].string ?? ""
        
        /*Tìm hoặc tạo mới người mượn từ Id trả về*/
        if let borrowRecordId = json["borrowRecordId"].int {
            newBook.borrowRecordId = borrowRecordId
            newBook.lenderId = json["borrowFromUserId"].int ?? -1
            newBook.lenderName = json["borrowFromUserName"].string ?? ""
        }
        
        return newBook
    }
}
