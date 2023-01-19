//
//  CommonNetworkService.swift
//  gat
//
//  Created by Vũ Kiên on 04/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import RxSwift

class CommonNetworkService {
    static var shared: CommonNetworkService = CommonNetworkService()
    
    fileprivate var service: ServiceNetwork
    fileprivate let dispatcher: Dispatcher = APIDispatcher()
    var progress: Observable<Double> {
        return self.service.progress.asObservable()
    }
    
    fileprivate init() {
        self.service = ServiceNetwork.shared
    }
    
    func uploadImage(base64: String) -> Observable<String> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                guard let data = base64.data(using: .utf8) else {
                    return Observable.empty()
                }
                service.builder()
                    .setPathUrl(path: "common/upload_image_base64")
                return service.upload(multiPart: ["base64": data])
            })
            .map { $0["data"]["resultInfo"].string ?? "" }
    }
    
    func check(version: String) -> Observable<Bool> {
        return Observable<ServiceNetwork>.just(self.service)
            .flatMapLatest({ (service) -> Observable<JSON> in
                service
                    .builder()
                    .setPathUrl(path: "common/check_version")
                    .method(.get)
                    .with(parameters: ["deviceType": 1, "version": version])
                if let token = Session.shared.accessToken {
                    service.withHeaders(key: "Authorization", value: token)
                }
                return service.request()
            })
            .map({ (json) -> Bool in
                return json["data"]["needToUpdate"].bool ?? false
            })
    }
    
    func startApp(uuid: String) -> Observable<()> {
        self.dispatcher.fetch(request: StartAppRequest(uuid: uuid), handler: StartAppResponse())
    }
}
