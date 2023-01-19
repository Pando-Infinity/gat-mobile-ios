//
//  ReadingStatusBook.swift
//  gat
//
//  Created by jujien on 1/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire

class ReadingStatusBookRequest: APIRequest {
    var path: String {
        return AppConfig.sharedConfig.get("reading_stt")
    }
    
    fileprivate let editionId: Int
    
    var method: HTTPMethod { return .get }
    
    var parameters: Parameters? {
        return ["editionId": self.editionId]
    }
    
    init(editionId: Int) {
        self.editionId = editionId
    }
}

class UpdateReadingStatusBookRequest: ReadingStatusBookRequest {
    override var path: String {
        return AppConfig.sharedConfig.get("update_reading_stt")
    }
    
    override var method: HTTPMethod { return .post }
    
    override var parameters: Parameters? {
        return ["editionId": self.editionId, "bookId": self.bookId, "readingStatus": self.readingStatus.status.rawValue]
    }
    
    fileprivate var bookId: Int
    fileprivate var readingStatus: ReadingStatus
    
    override init(editionId: Int) {
        self.bookId = 0
        self.readingStatus = ReadingStatus()
        super.init(editionId: editionId)
    }
    
    convenience init(editionId: Int, bookId: Int, readingStatus: ReadingStatus) {
        self.init(editionId: editionId)
        self.bookId = bookId
        self.readingStatus = readingStatus
    }
}

class ReadingStatusBookResponse: APIResponse {
    typealias Resource = ReadingStatus
    
    fileprivate let book: BookInfo
    
    init(book: BookInfo) {
        self.book = book
    }
    
    func map(data: Data?, statusCode: Int) -> ReadingStatus? {
        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
        let readingStatus = ReadingStatus()
        let data = json["data"]
        readingStatus.readingId = data["readingId"].int
        readingStatus.status = StatusReadBook(rawValue: data["readingStatus"].int ?? -1) ?? .remove
        readingStatus.bookInfo = self.book
        return readingStatus
    }
}
