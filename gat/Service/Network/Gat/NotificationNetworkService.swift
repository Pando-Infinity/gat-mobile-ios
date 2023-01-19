//
//  NotificationNetworkService.swift
//  gat
//
//  Created by Vũ Kiên on 28/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import SwiftyJSON

class NotificationNetworkService {
    static var shared: NotificationNetworkService = NotificationNetworkService()
    
    fileprivate var service: ServiceNetwork
    var progress: Observable<Double> {
        return self.service.progress.asObserver()
    }
    
    fileprivate init() {
        self.service = ServiceNetwork.shared
    }
    
    func list(page: Int = 1, per_page: Int = 15) -> Observable<[UserNotification]>{
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: AppConfig.sharedConfig.get("user_notification"))
                    .method(.get)
                    .with(parameters: ["page": page, "per_page": per_page])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> [UserNotification] in
                print(json)
                return json["data"]["resultInfo"].array?.map({ (json) -> UserNotification in
                    let userNotification = UserNotification()
                    userNotification.notificationId = json["notificationId"].int ?? 0
                    userNotification.notificationType = json["notificationType"].int ?? 0
                    userNotification.destId = json["destId"].int ?? 0
                    userNotification.user = Profile()
                    userNotification.user?.id = json["sourceId"].int ?? 0
                    userNotification.user?.name = json["sourceName"].string ?? ""
                    userNotification.user?.imageId = json["sourceImage"].string ?? ""
                    userNotification.targetName = json["targetName"].string ?? ""
                    userNotification.referId = json["referId"].int ?? 0
                    userNotification.pullFlag = json["pullFlag"].bool ?? false
                    userNotification.beginTime = Date(timeIntervalSince1970: (json["beginTime"].double ?? 0.0) / 1000.0)
                    userNotification.targetId = json["targetId"].int ?? 0
                    userNotification.referName = json["referName"].string ?? ""
                    userNotification.relationCount = json["relatedCount"].int ?? 0
                    return userNotification
                }) ?? []
            })
    }
    
    func notifyTotal() -> Observable<Int> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: AppConfig.sharedConfig.get("user_notification"))
                    .method(.get)
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map { UserNotification.parseNotify(json: $0) }
    }
    
    func push(receiver: Profile, message: String) -> Observable<()> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: AppConfig.sharedConfig.get("push_message"))
                    .method(.post)
                    .with(parameters: ["receiverId": receiver.id, "Message": message])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> () in
                print(json)
                return ()
            })
    }
}
