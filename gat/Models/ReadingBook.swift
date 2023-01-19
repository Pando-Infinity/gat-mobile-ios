//
//  ReadingBook.swift
//  gat
//
//  Created by jujien on 1/9/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON

class ReadingBook {
    var id: Int
    var book: BookInfo?
    var user: Profile?
    var status: Status
    var currentPage: Int
    var lastReadDate: Date?
    var followDate: Date?
    var startDate: Date?
    var completedDate: Date?
    var editionId: Int = 0
    var pageNum: Int = 0
    
    var progress: Float = 0.0
    
    init(id: Int, book: BookInfo?, user: Profile?, status: Status, currentPage: Int, lastReadDate: Date?, followDate: Date?, startDate: Date?, completedDate: Date?, editionId: Int, pageNum: Int) {
        self.id = id
        self.book = book
        self.user = user
        self.status = status
        self.currentPage = currentPage
        self.lastReadDate = lastReadDate
        self.followDate = followDate
        self.startDate = startDate
        self.completedDate = completedDate
        self.editionId = editionId
        self.pageNum = pageNum
        
        calProcess()
    }
    
    private func calProcess() {
        if pageNum > 0 {
            progress = Float(currentPage) / Float(pageNum)
        }
    }
    
    init() {
        self.id = 0
        self.book = BookInfo()
        self.user = Profile()
        self.status = .none
        self.currentPage = 0
    }
    
    init(json: JSON) {
        self.id = json["readingId"].int ?? 0
        self.book = BookInfo()
        let edition = json["edition"]
        self.book?.editionId = edition["editionId"].int ?? 0
        self.book?.title = edition["title"].string ?? ""
        self.book?.author = edition["authorName"].string ?? ""
        self.book?.descriptionBook = edition["description"].string ?? ""
        self.book?.imageId = edition["imageId"].string ?? ""
        self.book?.totalPage = edition["pageNum"].int ?? 0
        self.currentPage = json["readPage"].int ?? 0
        self.user = Profile()
        self.user?.id = json["userId"].int ?? 0
        self.status = Status(rawValue: json["readingStatusId"].int ?? -1) ?? .none
        if let followDate = json["followDate"].double {
            self.followDate = Date(timeIntervalSince1970: followDate / 1000.0)
        }
        if let startDate = json["startDate"].double {
            self.startDate = Date(timeIntervalSince1970: startDate / 1000.0)
        }
        if let completeDate = json["completeDate"].double {
            self.completedDate = Date(timeIntervalSince1970: completeDate / 1000.0)
        }
    }
}

extension ReadingBook {
    enum Status: Int {
        case none = -1
        case finish = 0
        case reading = 1
    }
}


extension ReadingBook {
}
