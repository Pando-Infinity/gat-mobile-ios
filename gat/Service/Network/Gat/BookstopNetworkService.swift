//
//  BookstopNetworkService.swift
//  gat
//
//  Created by Vũ Kiên on 04/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RxSwift
import CoreLocation

enum SearchBookstopOption: Int {
    case all = -1
    case `public` = 2
    case organization = 3
}

enum SearchMemberOption: Int {
    case all = -1
    case random = 11
}

enum RequestBookstopStatus: Int {
    case join = 0
    case leave = 2
    case cancel = 3
}

enum ShowBookstopDetailStatus: Int {
    case additional = 0
    case detail = 1
}

enum SortingBookstop: Int {
    case distance = 1
    case newest = 2
    case alphabet = 3
}

class BookstopNetworkService {
    static var shared: BookstopNetworkService = BookstopNetworkService()
    
    fileprivate var service: ServiceNetwork
    var progress: Observable<Double> {
        return self.service.progress.asObserver()
    }
    
    fileprivate init() {
        self.service = ServiceNetwork.shared
    }
    
    func findBookstop(location: CLLocationCoordinate2D, searchKey: String = "", option: SearchBookstopOption = .all, showDetail: ShowBookstopDetailStatus = .additional, sortingBy: SortingBookstop = .distance, page: Int = 1, per_page: Int = 10) -> Observable<[Bookstop]> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest { (service) -> Observable<JSON> in
                var paramters: [String: Any] = ["latitude": location.latitude, "longitude": location.longitude, "type": option.rawValue, "show_detail": showDetail.rawValue, "sorting": sortingBy.rawValue, "page": page, "per_page": per_page]
                if !searchKey.isEmpty {
                    paramters["search_key"] = searchKey
                }
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                service
                    .builder()
                    .setPathUrl(path: "bookstops/list")
                    .method(.get)
                    .with(parameters: paramters)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            }
            .flatMap({ (json) -> Observable<[Bookstop]> in
                return Observable<[Bookstop]>.from(optional: json["data"].array?.map({ (json) -> Bookstop in
                    let bookstop = Bookstop()
                    bookstop.profile = Profile()
                    let id = json["userId"].int ?? 0
                    bookstop.id = id
                    bookstop.profile?.parse(json: json)
                    bookstop.distance = json["distance"].double ?? 0.0
                    bookstop.memberType = MemberType(rawValue: json["memberType"].int ?? 0) ?? .open
                    if showDetail == .detail {
                        bookstop.images = BookstopImage.parse(json: json)
                        if (bookstop.profile?.userTypeFlag == .organization) {
                            let organization = BookstopKindOrganization()
                            organization.totalEdition = json["totalEdition"].int ?? 0
                            organization.totalMemeber = json["totalMember"].int ?? 0
                            bookstop.kind = organization
                        } else {
                            let `public` = BookstopKindPulic()
                            `public`.sharingBook = json["totalEdition"].int ?? 0
                            bookstop.kind = `public`
                        }
                        
                    } else {
                        
                    }
                    return bookstop
                }))
            })
    }
    
    func info(bookstop: Bookstop) -> Observable<Bookstop> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "bookstops/\(bookstop.id)/info")
                    .method(.get)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> Bookstop in
                let data = json["data"]
                let bookstop = Bookstop()
                bookstop.id = data["userId"].int ?? 0
                bookstop.profile?.parse(json: data)
                bookstop.images = BookstopImage.parse(json: data)
                bookstop.fbLink = data["fbLink"].string
                bookstop.insLink = data["insLink"].string
                bookstop.twLink = data["twLink"].string
                bookstop.memberType = MemberType(rawValue: data["memberType"].int ?? 0) ?? .open
                if bookstop.profile?.userTypeFlag == .organization {
                    let kind = BookstopKindOrganization()
                    kind.totalEdition = data["totalEdition"].int ?? 0
                    kind.totalMemeber = data["totalMember"].int ?? 0
                    bookstop.kind = kind
                } else {
                    let kind = BookstopKindPulic()
                    kind.sharingBook = data["totalEdition"].int ?? 0
                }
                return bookstop
            })
    }
    
    func memeberActivities(in bookstop: Bookstop, page: Int = 1, per_page: Int = 10) -> Observable<[MemberActivity]> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service.builder()
                    .setPathUrl(path: "bookstops/\(bookstop.id)/activities")
                    .method(.get)
                    .with(parameters: ["page": page, "per_page": per_page])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> [MemberActivity] in
                return json["data"].array?.map({ (json) -> MemberActivity in
                    let memberActivity = MemberActivity(bookstop: bookstop)
                    memberActivity.activityId = json["activityId"].int ?? 0
                    
                    memberActivity.book.editionId = json["targetId"].int ?? 0
                    memberActivity.book.title = json["targetTitle"].string ?? ""
                    memberActivity.book.imageId = json["targetImageId"].string ?? ""
                    memberActivity.book.author = json["targetAuthor"].string ?? ""
                    
                    memberActivity.activityType = json["activityType"].int ?? 0
                    
                    memberActivity.user.id = json["memberId"].int ?? 0
                    memberActivity.user.name = json["memberName"].string ?? ""
                    memberActivity.user.imageId = json["memberImageId"].string ?? ""
                    
                    memberActivity.status = MemberActivity.Status(rawValue: json["status"].int ?? 0)
                    
                    memberActivity.activityTime = .init(timeIntervalSince1970: (json["activityTime"].double ?? 0.0) / 1000.0)
                    return memberActivity
                }) ?? []
            })
    }
    
    func listBook(of bookstop: Bookstop, searchKey: String? = nil, option: SearchBookOption = .random, page: Int = 1, per_page: Int = 12) -> Observable<[UserSharingBook]> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                var parameters: [String: Any] = ["search_option": option.rawValue, "page": page, "per_page": per_page]
                if let key = searchKey {
                    parameters["search_key"] = key
                }
                service
                    .builder()
                    .setPathUrl(path: "bookstops/\(bookstop.id)/sharing_editions")
                    .method(.get)
                    .with(parameters: parameters)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> [UserSharingBook] in
                return json["data"].array?.map({ (json) -> UserSharingBook in
                    let userSharingBook = UserSharingBook()
                    userSharingBook.profile = bookstop.profile!
                    userSharingBook.bookInfo.editionId = json["editionId"].int ?? 0
                    userSharingBook.bookInfo.bookId = json["bookId"].int ?? 0
                    userSharingBook.bookInfo.title = json["title"].string ?? ""
                    userSharingBook.bookInfo.author = json["author"].string ?? ""
                    userSharingBook.bookInfo.rateAvg = json["rateAvg"].double ?? 0.0
                    userSharingBook.bookInfo.imageId = json["imageId"].string ?? ""
                    if let recordId = json["recordId"].int {
                        userSharingBook.request = BookRequest()
                        userSharingBook.request?.recordId = recordId
                        userSharingBook.request?.recordStatus = RecordStatus(rawValue: json["recordStatus"].int ?? -1)
                    }
                    return userSharingBook
                }) ?? []
            })
    }
    
    func totalSearchBook(of bookstop: Bookstop, searchKey: String? = nil, option: SearchBookOption = .random) -> Observable<Int> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                var parameters: [String: Any] = ["search_option": option.rawValue]
                if let key = searchKey {
                    parameters["search_key"] = key
                }
                service
                    .builder()
                    .setPathUrl(path: "bookstops/\(bookstop.id)/sharing_editions_total")
                    .method(.get)
                    .with(parameters: parameters)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map { $0["data"].int ?? 0 }
    }

    
    func totalBook(of bookstop: Bookstop) -> Observable<Int> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "bookstops/\(bookstop.id)/sharing_editions_total")
                    .method(.get)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map { $0["data"].int ?? 0 }
    }
    
    func members(of bookstop: Bookstop, option: SearchMemberOption = .all, searchKey: String? = nil, page: Int = 1, per_page: Int = 10) -> Observable<[UserPublic]> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) ->  Observable<JSON> in
                var parameters: [String: Any] = ["search_option": option.rawValue, "page": page, "per_page": per_page]
                if let key = searchKey {
                    parameters["searchKeyword"] = key
                }
                service
                    .builder()
                    .setPathUrl(path: "bookstops/\(bookstop.id)/members")
                    .method(.get)
                    .with(parameters: parameters)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> [UserPublic] in
                return json["data"].array?.map({ (json) -> UserPublic in
                    let userPublic = UserPublic()
                    userPublic.profile.id = json["userId"].int ?? 0
                    userPublic.profile.address = json["address"].string ?? ""
                    userPublic.profile.userTypeFlag = UserType(rawValue: json["userTypeFlag"].int ?? 1) ?? .normal
                    userPublic.profile.name = json["name"].string ?? ""
                    userPublic.profile.imageId = json["imageId"].string ?? ""
                    userPublic.sharingCount = json["sharingCount"].int ?? 0
                    userPublic.reviewCount = json["reviewCount"].int ?? 0
                    return userPublic
                }) ?? []
            })
    }
    
    func request(in bookstop: Bookstop, with status: RequestBookstopStatus = .join, intro: String? = nil) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                var parameters: [String: Any] = ["status": status.rawValue, "bookstopId": bookstop.id]
                if let intro = intro {
                    parameters["intro"] = intro
                }
                service
                    .builder()
                    .setPathUrl(path: "bookstops/join_request")
                    .method(.post)
                    .with(parameters: parameters)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request(encoding: JSONEncoding.default)
            })
            .map({ (json) -> () in
                print(json)
                return ()
            })
    }
    
}


//class BookstopNetworkRequest:APIRequest {
//    var path: String {return "bookstop/\(bookstopId)/info"}
//
//    fileprivate let bookstopId:Int
//
//    init(bookstopId:Int) {
//        self.bookstopId = bookstopId
//    }
//}
//
//class BookstopNetworkRespone:APIResponse {
//
//    typealias Resource = Bookstop
//
//    func map(data: Data?, statusCode: Int) -> Bookstop? {
//        guard let json = self.json(from: data, statusCode: statusCode) else { return nil }
//        let data = json["data"]
//        let bookstop = Bookstop()
//        bookstop.id = data["userId"].int ?? 0
//        bookstop.profile?.parse(json: data)
//        bookstop.images = BookstopImage.parse(json: data)
//        bookstop.fbLink = data["fbLink"].string
//        bookstop.insLink = data["insLink"].string
//        bookstop.twLink = data["twLink"].string
//        bookstop.memberType = MemberType(rawValue: data["memberType"].int ?? 0) ?? .open
//        if bookstop.profile?.userTypeFlag == .organization {
//            let kind = BookstopKindOrganization()
//            kind.totalEdition = data["instanceSummary"]["sharingCount"].int ?? 0
//            kind.totalMemeber = data["memberSummary"]["memberCount"].int ?? 0
//            bookstop.kind = kind
//        } else {
//            let kind = BookstopKindPulic()
//            kind.sharingBook = data["instanceSummary"]["sharingCount"].int ?? 0
//        }
//        return bookstop
//    }
//}
