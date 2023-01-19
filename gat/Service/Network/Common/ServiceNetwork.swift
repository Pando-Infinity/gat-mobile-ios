//
//  Service.swift
//  gat
//
//  Created by Vũ Kiên on 23/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON

protocol NetworkService {
    var dispatcher: Dispatcher { get set  }
}

class ServiceNetwork {
    
    static var shared: ServiceNetwork {
        return ServiceNetwork()
    }
    
    fileprivate var baseUrl: String = ""
    
    fileprivate var headers: HTTPHeaders = ["Accept-Language": NSLocalizedString("Accept-Language", comment: "")]
    
    fileprivate var parameters: Parameters? = nil
    
    fileprivate var method: HTTPMethod = .get
    
    var progress: BehaviorSubject<Double>
    
    fileprivate init() {
        self.progress = BehaviorSubject(value: 0.0)
    }
    
    @discardableResult
    func setPathUrl(path: String) -> ServiceNetwork {
        self.baseUrl += path
        return self
    }
    
    @discardableResult
    func withHeaders(key: String, value: String) -> ServiceNetwork {
        self.headers[key] = value
        return self
    }
    
    @discardableResult
    func with(headers: [String: String]) -> ServiceNetwork {
        self.headers = headers
        return self
    }
    
    @discardableResult
    func withParameters(key: String, value: Any) -> ServiceNetwork {
        if self.parameters == nil {
            self.parameters = [:]
        }
        self.parameters?[key] = value
        return self
    }
    
    @discardableResult
    func with(parameters: [String: Any]) -> ServiceNetwork {
        self.parameters = parameters
        return self
    }
    
    @discardableResult
    func method( _ method: HTTPMethod) -> ServiceNetwork {
        self.method = method
        return self
    }
    
    @discardableResult
    func builder() -> ServiceNetwork {
        self.baseUrl = AppConfig.sharedConfig.config(item: "api_url")!
        self.parameters = [:]
        self.headers = ["Accept-Language": NSLocalizedString("Accept-Language", comment: "")]
        return self
    }
    
    func request(encoding: ParameterEncoding = URLEncoding.default) -> Observable<JSON> {
        return Observable<JSON>
            .create({ [weak self] (observer) -> Disposable in
                let request = Alamofire.request(self?.baseUrl ?? "", method: self?.method ?? .get, parameters: self?.parameters, encoding: encoding, headers: self?.headers).downloadProgress(closure: { (progress) in
                    self?.progress.onNext(progress.fractionCompleted)
                    if progress.fractionCompleted.isEqual(to: 1.0) {
                        self?.progress.onCompleted()
                    }
                })
                    .responseJSON(completionHandler: { [weak self] (response) in
                        print(response.request?.url?.absoluteString as Any)
                        switch response.result {
                        case .success(let value):
                            if let json = self?.responseJSON(value: value, status: response.response?.statusCode) {
                                observer.onNext(json)
                            }
                            
                            if let error = self?.responseError(value: value, status: response.response?.statusCode, url: response.request?.url) {
                                observer.onError(error)
                            }
                            break
                        case .failure(let error):
                            print("error: \(error.localizedDescription)")
                            observer.onError(ServiceError.init(domain: response.request?.url?.absoluteString ?? "", code: -1, userInfo: ["message": error.localizedDescription]))
                            break
                        }
                        
                    })
                return Disposables.create {
                    request.cancel()
                }
            })
    }
    
    func upload(multiPart: [String: Data]) -> Observable<JSON> {
        return Observable<JSON>.create({ [weak self] (observer) -> Disposable in
            Alamofire.upload(multipartFormData: { (multipartFormData) in
                multiPart.keys.forEach({ (key) in
                    multipartFormData.append(multiPart[key]!, withName: key)
                })
            }, usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold, to: self?.baseUrl ?? "", method: .post, encodingCompletion: { [weak self] (result) in
                switch result {
                case .success(let request, _, _):
                    request.uploadProgress(closure: { [weak self] (progress) in
                        self?.progress.onNext(progress.fractionCompleted)
                    }).responseJSON(completionHandler: { [weak self] (response) in
                        print(response.request?.url?.absoluteString as Any)
                        switch response.result {
                        case .success(let value):
                            if let json = self?.responseJSON(value: value, status: response.response?.statusCode) {
                                observer.onNext(json)
                            }
                            
                            if let error = self?.responseError(value: value, status: response.response?.statusCode, url: response.request?.url) {
                                observer.onError(error)
                            }
                            break
                        case .failure(let error):
                            observer.onError(ServiceError.init(domain: response.request?.url?.absoluteString ?? "", code: -1, userInfo: ["message": error.localizedDescription]))
                            break
                        }
                        observer.onCompleted()
                    })
                    break
                case .failure(let error):
                    print("error: " + error.localizedDescription)
                    observer.onError(ServiceError.init(domain: "", code: -1, userInfo: ["message": error.localizedDescription]))
                    break
                }
            })
            return Disposables.create ()
        })
    }
    
    fileprivate func responseJSON(value: Any?, status: Int?) -> JSON? {
        guard let value = value, let status = status, status >= StatusCode.ok.rawValue && status < StatusCode.multipleChoices.rawValue else {
            return nil
        }
        
        return JSON(value)
    }
    
    fileprivate func responseError(value: Any?, status: Int?, url: URL?) -> ServiceError? {
        guard let value = value, let status = status, let url = url?.absoluteString, status >= StatusCode.badRequest.rawValue else {
            return nil
        }
        return ServiceError(domain: url, code: status, userInfo: ["message": JSON(value)["message"].string ?? ""])
    }
}
