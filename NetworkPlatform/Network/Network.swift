//
//  Network.swift
//  gat
//
//  Created by Hung Nguyen on 12/7/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import RxAlamofire
import RxSwift
import SwiftyJSON

final class Network<T: BaseModel> {

    private let endPoint: String
    private let scheduler: ConcurrentDispatchQueueScheduler
    
    private var auth: String

    init(_ endPoint: String) {
        self.endPoint = endPoint
        self.scheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 1))
        self.auth = "Bearer \(Session.shared.accessToken ?? "")"
        print("auth: \(auth)")
    }

    func getData(_ path: String, isNeedAuth: Bool = true) -> Observable<T> {
        let absolutePath = "\(endPoint)/\(path)"
        
        if !isNeedAuth {
            auth = ""
        }
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("------------ END REQUEST INPUT\n")
        
        return RxAlamofire
            .request(.get, absolutePath, headers: ["Authorization": auth])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .map(proccess)
    }
    
    func getDataV1(_ path: String, isNeedAuth: Bool = true) -> Observable<T> {
        let absolutePath = "\(endPoint)/\(path)"
        
        if !isNeedAuth {
            auth = ""
        }
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("------------ END REQUEST INPUT\n")
        
        return RxAlamofire
            .request(.get, absolutePath, headers: ["Authorization": Session.shared.accessToken ?? ""])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .map(proccess)
    }

    func getItem(_ path: String, itemId: String) -> Observable<T> {
        let absolutePath = "\(endPoint)\(path)/\(itemId)"
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("------------ END REQUEST INPUT\n")
        
        return RxAlamofire
            .request(.get, absolutePath, headers: ["Authorization": auth])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .do(onNext: { (response) in
                guard let value = response.value else { return }
                print("PATH: \(absolutePath)")
                print(JSON(value))
            })
            .map(proccess)
    }
    
    func getItem(_ path: String, params: String) -> Observable<T> {
        let absolutePath = "\(endPoint)\(path)\(params)"
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("------------ END REQUEST INPUT\n")
        
        return RxAlamofire
            .request(.get, absolutePath, headers: ["Authorization": auth])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .do(onNext: { (response) in
                guard let value = response.value else { return }
                print("PATH: \(absolutePath)")
                print(JSON(value))
            })
            .map(proccess)
    }
    
    func postData(_ path: String, parameters: [String: Any], encoding:ParameterEncoding = URLEncoding.default) -> Observable<T> {
        let absolutePath = "\(endPoint)/\(path)"
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("body: %@", parameters ?? "No Body")
        print("------------ END REQUEST INPUT\n")
        
        return RxAlamofire
            .request(.post, absolutePath, parameters: parameters, encoding: encoding, headers: ["Authorization": auth, "Content-Type": "application/json"])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .map(proccess)
    }
    
    func patchData(_ path: String, parameters: [String: Any], encoding:ParameterEncoding = URLEncoding.default) -> Observable<T> {
        let absolutePath = "\(endPoint)/\(path)"
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("body: %@", parameters ?? "No Body")
        print("------------ END REQUEST INPUT\n")
        
        return RxAlamofire
            .request(.patch, absolutePath, parameters: parameters, encoding: encoding, headers: ["Authorization": auth, "Content-Type": "application/json"])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .map(proccess)
    }
    
    func putData(_ path: String, parameters: [String: Any], encoding: ParameterEncoding = JSONEncoding.default) -> Observable<T> {
        let absolutePath = "\(endPoint)/\(path)"
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("body: %@", parameters ?? "No Body")
        print("------------ END REQUEST INPUT\n")
        return RxAlamofire
            .request(.put, absolutePath, parameters: parameters, encoding: encoding, headers: ["Authorization": auth])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .map(proccess)
        
    }
    
    func postItem(_ path: String, parameters: [String: Any]) -> Observable<T> {
        let absolutePath = "\(endPoint)/\(path)"
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("body: %@", parameters ?? "No Body")
        print("------------ END REQUEST INPUT\n")
        
        return RxAlamofire
            .request(.post, absolutePath, parameters: parameters, headers: ["Authorization": auth])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .map(proccess)
    }

    func updateItem(_ path: String, itemId: String, parameters: [String: Any]) -> Observable<T> {
        let absolutePath = "\(endPoint)/\(path)/\(itemId)"
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("body: %@", parameters ?? "No Body")
        print("------------ END REQUEST INPUT\n")
        
        return RxAlamofire
            .request(.post, absolutePath, parameters: parameters, headers: ["Authorization": auth])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .map(proccess)
    }

    func deleteItem(_ path: String, itemId: String) -> Observable<T> {
        let absolutePath = "\(endPoint)/\(path)/\(itemId)"
        
        print("\n------------REQUEST INPUT")
        print("link: %@", absolutePath)
        print("------------ END REQUEST INPUT\n")
        
        return RxAlamofire
            .request(.delete, absolutePath, headers: ["Authorization": auth])
            .validate(statusCode: 200..<500)
            .debug()
            .observeOn(scheduler)
            .flatMap { $0.rx.responseJSON() }
            .map(proccess)
    }
    
    func proccess(_ response: DataResponse<Any>) throws -> T {
        switch response.result {
        case .success(let value):
//            print("can run on success: \(value)")
            if let statusCode = response.response?.statusCode {
                if statusCode == 200 {
                    return T.init(json: try JSON(data: response.data!))
                } else {
                    let jsonObj = try JSON(data: response.data!)
                    if let message = jsonObj["message"].string {
                        print("error message; \(message)")
                        throw BaseError.apiFailure(error: ErrorResponse(message: message))
                    } else {
                        throw BaseError.httpError(httpCode: statusCode)
                    }
                }
            } else {
                print("can run on error in else case")
                throw BaseError.unexpectedError
            }
        case .failure(let error):
            print("can run on error: \(error)")
            throw BaseError.networkError
        }
    }
}

