//
//  Dispatcher.swift
//  gat
//
//  Created by Vũ Kiên on 02/10/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire

protocol Dispatcher {
    var host: String { get }
    
    var progress: Observable<Progress> { get }
    
    func fetch<Request: APIRequest, Response: APIResponse>(request: Request, handler: Response) -> Observable<Response.Resource>
}

extension Dispatcher {
    var host: String {
        return AppConfig.sharedConfig.config(item: "api_url")!
    }
    
    var progress: Observable<Progress> { .empty() }
    
    func fetch<Request: APIRequest, Response: APIResponse>(request: Request, handler: Response) -> Observable<Response.Resource> {
        return request
            .request(dispatcher: self)
            .flatMap({ (dataRequest) -> Observable<Response.Resource> in
                return Observable<Response.Resource>
                    .create({ (observer) -> Disposable in
                        (dataRequest as? DataRequest)?.responseJSON(completionHandler: { (response) in
                            
                            print(response.request?.url?.absoluteString as Any)
                            
                            switch response.result {
                            case .success(_):
                                if let resource = handler.map(data: response.data, statusCode: response.response?.statusCode ?? 400) {
                                    observer.onNext(resource)
                                } else if let error = handler.error(data: response.data, statusCode: response.response?.statusCode ?? 400, url: response.request?.url?.absoluteString ?? "") {
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
                            dataRequest.cancel()
                        }
                    })
            })
    }
}

struct APIDispatcher: Dispatcher {
    
}

struct SearchDispatcher: Dispatcher {
    var host: String { return AppConfig.sharedConfig.config(item: "api_url_v2")! }
}

struct UploadDispatcher: Dispatcher {
    var host: String
    
    var fileManager: FileManager
    var threshold: UInt64
    
    var progress: Observable<Progress> { self.uploadProgress }
    
    fileprivate let uploadProgress: PublishSubject<Progress>
    
    init(host: String, fileManager: FileManager = .default, threshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold) {
        self.host = host
        self.fileManager = fileManager
        self.threshold = threshold
        self.uploadProgress = .init()
    }
    
    func fetch<Request, Response>(request: Request, handler: Response) -> Observable<Response.Resource> where Request : APIRequest, Response : APIResponse {
        return .create { (observer) -> Disposable in
            Alamofire.upload(multipartFormData: { (form) in
                request.parameters?.compactMapValues { $0 as? Data }.forEach({ (key, value) in
                    form.append(value, withName: key)
                })
            }, usingThreshold: self.threshold, to: self.host + request.path, method: request.method, headers: request.headers) { (result) in
                switch result {
                case .failure(let error):
                    print("error: \(error.localizedDescription)")
                    observer.onError(ServiceError.init(domain: "\(self.host + request.path)", code: -1, userInfo: ["message": error.localizedDescription]))
                case .success(let request, _, _):
                    request.uploadProgress { (progress) in
                        self.uploadProgress.onNext(progress)
                    }
                    .responseJSON { (response) in
                        print(response.request?.url?.absoluteString as Any)
                        
                        switch response.result {
                        case .success(_):
                            if let resource = handler.map(data: response.data, statusCode: response.response?.statusCode ?? 400) {
                                observer.onNext(resource)
                            } else if let error = handler.error(data: response.data, statusCode: response.response?.statusCode ?? 400, url: response.request?.url?.absoluteString ?? "") {
                                observer.onError(error)
                            }
                        case .failure(let error):
                            print("error: \(error.localizedDescription)")
                            observer.onError(ServiceError.init(domain: response.request?.url?.absoluteString ?? "", code: -1, userInfo: ["message": error.localizedDescription]))
                        }
                    }
                    break
                }
            }
            return Disposables.create {
            }
        }
    }
    
}


struct DataDispatcher: Dispatcher {
    var host: String
    
    var progress: Observable<Progress> { self.downloadProgress.asObservable() }
    
    fileprivate let downloadProgress: PublishSubject<Progress>
    
    init(host: String) {
        self.host = host
        self.downloadProgress = .init()
    }
    
    func fetch<Request, Response>(request: Request, handler: Response) -> Observable<Response.Resource> where Request : APIRequest, Response : APIResponse {
        request.request(dispatcher: self)
            .flatMap { (dataRequest) -> Observable<Response.Resource> in
                return .create { (observer) -> Disposable in
                    (dataRequest as? DataRequest)?.downloadProgress(closure: { (progress) in
                        self.downloadProgress.onNext(progress)
                    })
                        .responseData(completionHandler: { (dataResponse) in
                            if let response = dataResponse.response, let url = response.url {
                                print(url)
                                if let resource = handler.map(data: dataResponse.data, statusCode: response.statusCode) {
                                    observer.onNext(resource)
                                } else if let error = handler.error(data: dataResponse.data, statusCode: response.statusCode, url: self.host + request.path) {
                                    observer.onError(error)
                                }
                            } else if let error = dataResponse.error {
                                observer.onError(ServiceError(domain: self.host + request.path, code: 400, userInfo: ["message": error.localizedDescription]))
                            }
                        })
                    return Disposables.create {
                        
                    }
                }
        }
    }
}
