//
//  SearchNetworkService.swift
//  gat
//
//  Created by Vũ Kiên on 10/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON
import Alamofire
import CoreLocation

class SearchNetworkService: NetworkService {
    
    var dispatcher: Dispatcher
    fileprivate var searchDispatcher: SearchDispatcher = .init()
    static var shared: SearchNetworkService = SearchNetworkService()
    
    fileprivate var service: ServiceNetwork
    var progress: Observable<Double> {
        return self.service.progress.asObserver()
    }
    
    fileprivate init() {
        self.dispatcher = APIDispatcher()
        self.service = ServiceNetwork.shared
    }
    
    func findNearBy(currentLocation: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D, page: Int = 1, per_page: Int = 10) -> Observable<([UserPublic], Int?)> {
        return Observable.just(self.service)
            .flatMapLatest { (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: AppConfig.sharedConfig.get("searchby_user"))
                    .method(.get)
                    .with(parameters: ["currentLat": currentLocation.latitude, "currentLong": currentLocation.longitude, "neLat": northEast.latitude, "neLong": northEast.longitude, "wsLat": southWest.latitude, "wsLong": southWest.longitude, "page": page, "per_page": per_page])
                if let access = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: access)
                }
                return service.request()
            }
            .map { (json) -> ([UserPublic], Int?) in
                return (json["data"]["resultInfo"].array?.map({ (json) -> UserPublic in
                    let user = UserPublic()
                    user.profile.id = json["userId"].int ?? 0
                    user.profile.address = json["address"].string ?? ""
                    user.profile.name = json["name"].string ?? ""
                    user.profile.imageId = json["imageId"].string ?? ""
                    user.profile.location = .init(latitude: json["latitude"].double ?? 0.0, longitude: json["longitude"].double ?? 0.0)
                    user.distance = json["distance"].double ?? 0.0
                    user.reviewCount = json["reviewCount"].int ?? 0
                    user.sharingCount = json["sharingCount"].int ?? 0
                    user.activeFlag = json["activeFlag"].bool ?? false
                    user.profile.userTypeFlag = UserType(rawValue: json["userTypeFlag"].int ?? 1) ?? .normal
                    return user
                }) ?? [], json["data"]["totalResult"].int)
            }
    }
    
    func book(title: String, page: Int, per_page: Int = 10) -> Observable<([BookSharing], Int)> {
        return self.searchDispatcher.fetch(request: SearchBookEditionRequest(type: .title(title), page: page, perPage: per_page), handler: SearchBookEditionResponse())
    }
    
    func author(name: String, page: Int, per_page: Int = 10) -> Observable<([BookSharing], Int)> {
        return self.searchDispatcher.fetch(request: SearchBookEditionRequest(type: .author(name), page: page, perPage: per_page), handler: SearchBookEditionResponse())
    }
    
    func historyBook(titles: [String]) -> Observable<()> {
        return self.dispatcher.fetch(request: TitleBookSearchHistoryRequest(keywords: titles), handler: TitleSearchHistoryResponse())
    }
    
    func historyAuthor(titles: [String]) -> Observable<()> {
        return self.dispatcher.fetch(request: AuthorSearchHistoryRequest(keywords: titles), handler: TitleSearchHistoryResponse())
    }
    
    func user(name: String, location: CLLocationCoordinate2D?, page: Int, per_page: Int = 10) -> Observable<([UserPublic], Int)> {
        return self.searchDispatcher.fetch(request: SearchUserRequest(keyword: name, location: location, page: page, perPage: per_page), handler: SearchUserResponse())
    }
}
