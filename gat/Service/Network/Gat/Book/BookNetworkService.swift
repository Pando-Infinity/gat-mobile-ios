//
//  BookNetworkService.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RxSwift
import CoreLocation

enum SortOption: Int {
    case activeTime = 0
    case distance = 1
    
    func toString() -> String {
        switch self {
        case .activeTime:
            return Gat.Text.SortByListSharingBook.UPTIME_STATUS_TITLE.localized()
        case .distance:
            return Gat.Text.SortByListSharingBook.DISTANCE_STATUS_TITLE.localized()
        }
    }
}

enum SearchBookOption: Int {
    case all = -1
    case notSharing = 0
    case sharing = 1
    case borrowing = 2
    case lost = 3
    case readInPlace = 4
    case limitedSharing = 5
    case limitedBorrowing = 6
    case borrowedMuch = 10
    case random = 11
    
    func toString() -> String {
        switch self {
        case .all:
            return "All"
        case .notSharing:
            return "Not Sharing"
        case .sharing:
            return "Sharing"
        case .borrowing:
            return "Borrowing"
        case .lost:
            return "Lost"
        case .readInPlace:
            return "Read in place"
        case .limitedSharing:
            return ""
        case .limitedBorrowing:
            return ""
        case .borrowedMuch:
            return "Borrowed Much"
        case .random:
            return ""
        }
    }
}

class BookNetworkService: NetworkService {
    static var shared: BookNetworkService = BookNetworkService()
    
    var dispatcher: Dispatcher
    fileprivate let searchDispatcher: Dispatcher
    
    fileprivate init() {
        self.dispatcher = APIDispatcher()
        self.searchDispatcher = SearchDispatcher()
    }
    
    func topBorrow(previousDay: Int = 7, page: Int = 1, per_page: Int = 10) -> Observable<[BookSharing]> {
        return self.dispatcher
            .fetch(
                request: TopBookBorrowRequest(previousDay: previousDay, page: page, per_page: per_page),
                handler: TopBookBorrowResponse()
        )
    }
    
    func sugesst(user: UserPrivate?, currentLocation: CLLocationCoordinate2D?, range: Int, page: Int = 1, per_page: Int = 12) -> Observable<([BookSharing], Int)> {
        return self.dispatcher
            .fetch(
                request: SuggestBookForUserInLocationRequest(userId: user?.id, location: currentLocation, range: range, page: page, per_page: per_page),
                handler: SuggestBookForUserInLocationResponse()
        )
    }
    
    func sugesst(mode: SuggestBookByModeRequest.SuggestBookMode, previousDays: Int, location: CLLocationCoordinate2D?, page: Int = 1, per_page: Int = 10) -> Observable<[BookSharing]> {
        return self.dispatcher
            .fetch(
                request: SuggestBookByModeRequest(suggestMode: mode, previousDays: previousDays, location: location, page: page, per_page: per_page),
                handler: SuggestBookByModeResponse()
        )
    }
    
    func info(editionId: Int) -> Observable<BookInfo> {
        return self.searchDispatcher
            .fetch(
                request: BookInfomationRequestV2(editionId: editionId),
                handler: BookInfomationResponseV2()
        )
    }
    
    func info(isbn: String) -> Observable<Int> {
        return self.searchDispatcher.fetch(request: BookISBNRequest(isbn: isbn), handler: BookISBNResponse())
    }
    
    func listSharing(book: BookInfo, user: Profile? = nil, location: CLLocationCoordinate2D? = nil, activeFlag: Bool = false, sortBy: SortOption, page: Int = 1, per_page: Int = 10) -> Observable<[UserSharingBook]> {
        return self.dispatcher
            .fetch(
                request: ListUserSharingBookRequest(editionId: book.editionId, userId: user?.id, location: location, activeFlag: activeFlag, sortBy: sortBy, page: page, per_page: per_page),
                handler: ListUserSharingBookResponse(book: book, user: user)
        )
    }
    
    func totalSharing(book: BookInfo, user: Profile? = nil, location: CLLocationCoordinate2D? = nil) -> Observable<Int> {
        return self.dispatcher
            .fetch(
                request: TotalListUserSharingBookRequest(editionId: book.editionId, userId: user?.id, location: location),
                handler: TotalListUserSharingBookResponse()
        )
    }
    
    func readingStatus(of bookInfo: BookInfo) -> Observable<ReadingStatus> {
        return self.dispatcher
            .fetch(
                request: ReadingStatusBookRequest(editionId: bookInfo.editionId),
                handler: ReadingStatusBookResponse(book: bookInfo)
        )
    }
    
    func updateStatus(of bookInfo: BookInfo, readingStatus: ReadingStatus) -> Observable<ReadingStatus> {
        return self.dispatcher.fetch(request: UpdateReadingStatusBookRequest.init(editionId: bookInfo.editionId, bookId: bookInfo.bookId, readingStatus: readingStatus), handler: ReadingStatusBookResponse(book: bookInfo))
    }
    
    func saving(bookInfo: BookInfo, value: Bool) -> Observable<()> {
        return self.dispatcher.fetch(request: AddBookmarkBookRequest(editionId: bookInfo.editionId, value: value), handler: IgnoreResponse())
    }
    
    func sharing(of user: Profile, options: [SharingBookVisitorUserRequest.FilterOption], keyword: String?, page: Int = 1, per_page: Int = 10) -> Observable<[UserSharingBook]> {
        return self.dispatcher.fetch(request: SharingBookVisitorUserRequest(userId: user.id, options: options, keyword: keyword, page: page, perpage: per_page), handler: SharingBookVisitorUserResponse())
    }
    
    func totalSharing(of user: Profile, options: [SharingBookVisitorUserRequest.FilterOption] = SharingBookVisitorUserRequest.FilterOption.allCases, keyword: String? = nil) -> Observable<Int> {
        return self.dispatcher.fetch(request: TotalSharingBookVisitorUserRequest(userId: user.id, options: options, keyword: keyword, page: 1, perpage: 10), handler: TotalSharingBookVisitorUserResponse())
    }
    
    func infos(editions: [Int]) -> Observable<[BookSharing]> {
        return self.dispatcher
            .fetch(request: ListBookInformationRequest(editions: editions), handler: ListBookInformationResponse())
    }
    
    func addNewBook(bookInfo: BookInfo, counting: Int = 1) -> Observable<()> {
        return self.dispatcher.fetch(request: AddNewBookRequest(book: bookInfo, counting: counting), handler: AddNewBookResponse())
    }
}
