//
//  ImageService.swift
//  gat
//
//  Created by jujien on 8/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift


 class ImageService {
    static let shared = ImageService()
    
    fileprivate var uploadDispatcher: Dispatcher
    fileprivate let downloadDispatcher: Dispatcher
    fileprivate let dispatcher: Dispatcher
    
    fileprivate init() {
        self.uploadDispatcher = UploadDispatcher(host: AppConfig.sharedConfig.config(item: "api_url")!)
        self.downloadDispatcher = DataDispatcher(host: AppConfig.sharedConfig.config(item: "api_url")!)
        self.dispatcher = DataDispatcher(host: AppConfig.sharedConfig.config(item: "api_url_v2")!)
    }
    
    func upload(data: String) -> Observable<DataProgress<String>> {
        self.uploadDispatcher = UploadDispatcher(host: AppConfig.sharedConfig.config(item: "api_url")!)
        let dispatcher = self.uploadDispatcher
        let result = dispatcher.fetch(request: UploadImageRequest(base64: data), handler: UploadImageResponse()).map { DataProgress<String>(data: $0, progress: nil) }
        let progress = dispatcher.progress.map { DataProgress<String>(data: nil, progress: $0) }
        return Observable.of(result, progress).merge()
    }
    
    func userUpload(data: String) -> Observable<DataProgress<String>>  {
        let dispatcher = self.dispatcher
        let result = dispatcher.fetch(request: UserUploadImageRequest(base64: data), handler: UserUploadImageResponse()).map { DataProgress<String>(data: $0, progress: nil) }
        let progress = dispatcher.progress.map { DataProgress<String>(data: nil, progress: $0) }
        return Observable.of(result, progress).merge()
    }
    
    func download(imageId: String, size: SizeImage) -> Observable<DataProgress<Data>> {
        let dispatcher = self.downloadDispatcher
        let result = dispatcher.fetch(request: DownloadImageRequest(imageId: imageId, size: size.rawValue), handler: DownloadImageResponse()).map { DataProgress<Data>(data: $0, progress: nil) }
        let progress = dispatcher.progress.map { DataProgress<Data>(data: nil, progress: $0) }
        return Observable.of(result, progress).merge()
    }
}
