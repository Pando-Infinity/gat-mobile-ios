//
//  Book.swift
//  Gatbook
//
//  Created by GaT-Kien on 2/21/17.
//  Copyright © 2017 GaT-Kien. All rights reserved.
//

import Foundation
import SwiftyJSON
import RealmSwift
import RxSwift

class BookEdition: Object {
    @objc dynamic var editionId = 0
    @objc dynamic var bookId = 0
    @objc dynamic var name = ""
    @objc dynamic var imageId = ""
    @objc dynamic var rateAvg = 0.0
    @objc dynamic var rateCount = 0
    @objc dynamic var reviewCount = 0
    @objc dynamic var author = ""
    @objc dynamic var borrowingCount = 0
    @objc dynamic var bookDescription = ""
    @objc dynamic var isbn10 = ""
    @objc dynamic var isbn13 = ""
    @objc dynamic var sharingCount = 0
    @objc dynamic var orderFlag = 0
    @objc dynamic var rowNumber = 0
    @objc dynamic var bookAmount = 0
    @objc dynamic var bookSharingType = 0 //= 1 tuong ung voi book dang duoc chia se
    
    /**Cài đặt khoá chính cho bảng*/
    override static func primaryKey() -> String {
        return "editionId"
    }
    
    //MARK: - Parse Json
    static func searchParse(json: JSON) -> [BookEdition] {
        var books = [BookEdition]()
        let data = json["data"]
        guard let resultInfo = data["resultInfo"].array else {
            return books
        }
        
        books = resultInfo.flatMap { (json) -> BookEdition? in
            guard let author = json["author"].string, let reviewCount = json["reviewCount"].int, let editionId = json["editionId"].int, let bookId = json["bookId"].int, let name = json["title"].string, let rateAvg = json["rateAvg"].double, let rowNumber = json["rowNumber"].int, let sharingCount = json["sharingCount"].int, let imageId = json["imageId"].string else {
                return nil
            }
            let bookEdition = BookEdition()
            bookEdition.author = author
            bookEdition.reviewCount = reviewCount
            bookEdition.editionId = editionId
            bookEdition.bookId = bookId
            bookEdition.name = name
            bookEdition.rateAvg = rateAvg
            bookEdition.rowNumber = rowNumber
            bookEdition.sharingCount = sharingCount
            bookEdition.imageId = imageId
            return bookEdition
        }
        return books
    }
    
    static func getDescripion(from json: JSON) -> String {
        let data = json["data"]
        let resultInfo = data["resultInfo"]
        guard let description = resultInfo["description"].string else {
            return ""
        }
        return description
    }
    
    static func getISBN(from json: JSON) -> [String] {
        let data = json["data"]
        let resultInfo = data["resultInfo"]
        guard let isbn10 = resultInfo["isbn10"].string, let isbn13 = resultInfo["isbn13"].string else {
            return []
        }
        return [isbn10, isbn13]
    }
    
    static func suggestionBookParse(json: JSON) -> [BookEdition] {
        let data = json["data"]
        guard let resultInfo = data["resultInfo"].array else {
            return []
        }
        return resultInfo.flatMap({ (json) -> BookEdition? in
            guard let editionId = json["editionId"].int, let bookId = json["bookId"].int, let title = json["title"].string, let imageId = json["imageId"].string, let author = json["author"].string, let rateAvg = json["rateAvg"].double, let sharingCount = json["sharingCount"].int, let reviewCount = json["reviewCount"].int, let orderFlag = json["orderFlag"].int, let rowNumber = json["rowNumber"].int else {
                return nil
            }
            let bookEdition = BookEdition()
            bookEdition.editionId = editionId
            bookEdition.bookId = bookId
            bookEdition.name = title
            bookEdition.imageId = imageId
            bookEdition.author = author
            bookEdition.rateAvg = rateAvg
            bookEdition.sharingCount = sharingCount
            bookEdition.reviewCount = reviewCount
            bookEdition.orderFlag = orderFlag
            bookEdition.rowNumber = rowNumber
            return bookEdition
        })
    }
    
    /**Trả về BookInstant từ JSON, nếu trong DB chưa lưu sẽ tạo mới, nếu đã lưu thì lấy bản cập nhật*/
    static func parseFrom(json: JSON) -> BookEdition? {
        guard let id = json["editionId"].int else {
            return nil
        }

        if let bookEdition = try! Realm().object(ofType: BookEdition.self, forPrimaryKey: id) {
            try! Realm().safeWrite {
                if json["bookId"].exists(), let bookId = json["bookId"].int {
                    bookEdition.bookId = bookId
                }
                if json["title"].exists(), let title = json["title"].string {
                    bookEdition.name = title
                }
                if json["description"].exists(), let description = json["description"].string {
                    bookEdition.bookDescription = description
                }
                if json["imageId"].exists(), let imageId = json["imageId"].string {
                    bookEdition.imageId = imageId
                }
                if json["author"].exists() {
                    if let author = json["author"].string {
                        bookEdition.author = author
                    }
                    if let authors = json["author"].array {
                        bookEdition.author = authors.flatMap({ (item) -> String in
                            if let authorName = item["authorName"].string {
                                return authorName
                            } else {
                                return ""
                            }
                        }).joined(separator: ", ")
                    }
                }
                if json["rateAvg"].exists(), let rateAvg = json["rateAvg"].double {
                    bookEdition.rateAvg = rateAvg
                }
                if json["rateCount"].exists(), let rateCount = json["rateCount"].int {
                    bookEdition.rateCount = rateCount
                }
                if json["reviewCount"].exists(), let reviewCount = json["reviewCount"].int {
                    bookEdition.reviewCount = reviewCount
                }
                if json["sharingCount"].exists(), let sharingCount = json["sharingCount"].int {
                    bookEdition.borrowingCount = sharingCount
                }
                if json["isbn10"].exists(), let isbn10 = json["isbn10"].string {
                    bookEdition.isbn10 = isbn10
                }
                if json["isbn13"].exists(), let isbn13 = json["isbn13"].string {
                    bookEdition.isbn13 = isbn13
                }
            }
            return bookEdition
        } else {
            let bookEdition = BookEdition()
            bookEdition.editionId = id
            bookEdition.name = json["title"].string ?? ""
            bookEdition.bookDescription = json["description"].string ?? ""
            bookEdition.bookId = json["bookId"].int ?? -1
            bookEdition.imageId = json["imageId"].string ?? ""
            bookEdition.author = json["author"].string ?? ""
            if let authors = json["author"].array {
                bookEdition.author = authors.flatMap({ (item) -> String in
                    if let authorName = item["authorName"].string {
                        return authorName
                    } else {
                        return ""
                    }
                }).joined(separator: ", ")
            }
            bookEdition.rateAvg = json["rateAvg"].double ?? 0.0
            bookEdition.rateCount = json["rateCount"].int ?? 0
            bookEdition.reviewCount = json["reviewCount"].int ?? 0
            bookEdition.borrowingCount = json["sharingCount"].int ?? 0
            bookEdition.orderFlag = json["orderFlag"].int ?? -1
            bookEdition.rowNumber = json["rowNumber"].int ?? -1 
            bookEdition.isbn10 = json["isbn10"].string ?? ""
            bookEdition.isbn13 = json["isbn13"].string ?? ""
            return bookEdition
        }
    }
}
