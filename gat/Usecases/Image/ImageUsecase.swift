//
//  ImageUsecase.swift
//  gat
//
//  Created by jujien on 8/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol ImageUsecase {
    func userUploadImageProgess(image: UIImage, compressionQuality: CGFloat, maxBytes: Int) -> Observable<Progress>
    
    func imageProgress(image: UIImage, compressionQuality: CGFloat, maxBytes: Int) -> Observable<Progress>
    
    func download(imageId: String, size: SizeImage) -> Observable<Data>
    
    func downloadImage(url: URL) -> Observable<Data>
    
    func upload(image: UIImage, compressionQuality: CGFloat, maxBytes: Int) -> Observable<String>
    
    func userUpload(image: UIImage, compressionQuality: CGFloat, maxBytes: Int) -> Observable<String>
}

struct DefaultImageUsecase: ImageUsecase {
    static let DEFAULT_IMAGE_FOLDER = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!).appendingPathComponent("image")
    
    fileprivate let disposeBag = DisposeBag()
    
    func userUploadImageProgess(image: UIImage, compressionQuality: CGFloat, maxBytes: Int) -> Observable<Progress> {
        let imageFolderURL = Self.DEFAULT_IMAGE_FOLDER
        try? FileManager.default.createDirectory(at: imageFolderURL, withIntermediateDirectories: true, attributes: [:])
        let imageURL = imageFolderURL.appendingPathComponent(String(format: "%@.jpg", UUID().uuidString))
        let local = self.saveToLocal(data: image.pngData() ?? Data(), url: imageURL)
        let remote = self.compress(image: image, compressionQuality: compressionQuality, maxBytes: maxBytes)
            .flatMap { (image) -> Observable<DataProgress<String>> in
                return ImageService.shared.userUpload(data: image.toBase64())
            }
            .do(onNext: { (progress) in
                    guard let imageId = progress.data else { return }
                    let ref = ReferenceURL(id: imageId, localURL: imageURL, serverURL: URL(string: AppConfig.sharedConfig.setUrlImage(id: imageId, size: .o))!, createDate: Date())
                    self.save(ref: ref)
                }, onError: { (error) in
                    do {
                        try FileManager.default.removeItem(at: imageURL)
                    } catch {
                        print(error.localizedDescription)
                    }
                })
                .map { (progress) -> Progress in
                    if let data = progress.data {
                        let urlImage = AppConfig.sharedConfig.setUrlImage(id: data, size: .o)
                        let p = Progress(totalUnitCount: 100)
                        p.completedUnitCount = 100
                        p.setUserInfoObject(URL(string: urlImage), forKey: .imageURLKey)
                        p.setUserInfoObject(SourceImage.server, forKey: .imageSourceKey)

                        return p
                    } else {
                        let p = progress.progress
                        p?.setUserInfoObject(SourceImage.server, forKey: .imageSourceKey)
                        p?.setUserInfoObject(imageURL, forKey: .imageURLKey)
                        return p!
                    }
            }
        return Observable.of(local, remote).merge()
    }
    
    func imageProgress(image: UIImage, compressionQuality: CGFloat, maxBytes: Int) -> Observable<Progress> {
        let imageFolderURL = Self.DEFAULT_IMAGE_FOLDER
        try? FileManager.default.createDirectory(at: imageFolderURL, withIntermediateDirectories: true, attributes: [:])
        let imageURL = imageFolderURL.appendingPathComponent(String(format: "%@.jpg", UUID().uuidString))
        let local = self.saveToLocal(data: image.pngData() ?? Data(), url: imageURL)
        let remote = self.compress(image: image, compressionQuality: compressionQuality, maxBytes: maxBytes)
            .flatMap { (image) -> Observable<DataProgress<String>> in
                return ImageService.shared.upload(data: image.toBase64())
            }
            .do(onNext: { (progress) in
                    guard let imageId = progress.data else { return }
                    let ref = ReferenceURL(id: imageId, localURL: imageURL, serverURL: URL(string: AppConfig.sharedConfig.setUrlImage(id: imageId, size: .o))!, createDate: Date())
                    self.save(ref: ref)
                }, onError: { (error) in
                    do {
                        try FileManager.default.removeItem(at: imageURL)
                    } catch {
                        print(error.localizedDescription)
                    }
                })
                .map { (progress) -> Progress in
                    if let data = progress.data {
                        let urlImage = AppConfig.sharedConfig.setUrlImage(id: data, size: .o)
                        let p = Progress(totalUnitCount: 100)
                        p.completedUnitCount = 100
                        p.setUserInfoObject(URL(string: urlImage), forKey: .imageURLKey)
                        p.setUserInfoObject(SourceImage.server, forKey: .imageSourceKey)

                        return p
                    } else {
                        let p = progress.progress
                        p?.setUserInfoObject(SourceImage.server, forKey: .imageSourceKey)
                        p?.setUserInfoObject(imageURL, forKey: .imageURLKey)
                        return p!
                    }
            }
        return Observable.of(local, remote).merge()
    }
    
    func download(imageId: String, size: SizeImage) -> Observable<Data> {
        return ImageService.shared.download(imageId: imageId, size: size).compactMap { $0.data }
            .do(onNext: { (data) in
                let imageFolderURL = Self.DEFAULT_IMAGE_FOLDER
                
                let imageURL = imageFolderURL.appendingPathComponent(String(format: "%@.jpg", UUID().uuidString))
                do {
                    try FileManager.default.createDirectory(at: imageFolderURL, withIntermediateDirectories: true, attributes: [:])
                    let ref = ReferenceURL(id: imageId, localURL: imageURL, serverURL: URL(string: AppConfig.sharedConfig.setUrlImage(id: imageId, size: .o))!, createDate: .init())
                    try data.write(to: imageURL)
                    self.save(ref: ref)
                } catch {
                    print(error.localizedDescription)
                }
            })
    }
    
    func downloadImage(url: URL) -> Observable<Data> {
        let request = URLRequest(url: url)
        return URLSession.shared.rx
            .data(request: request)
            .catchError { (error) -> Observable<Data> in
                print(error)
                return .empty()
            }
    }
    
    func upload(image: UIImage, compressionQuality: CGFloat, maxBytes: Int) -> Observable<String>  {
        self.compress(image: image, compressionQuality: compressionQuality, maxBytes: maxBytes)
            .flatMap { (image) -> Observable<String> in
                return ImageService.shared.upload(data: image.toBase64()).compactMap { $0.data }
        }
    }
    
    func userUpload(image: UIImage, compressionQuality: CGFloat, maxBytes: Int) -> Observable<String>  {
        self.compress(image: image, compressionQuality: compressionQuality, maxBytes: maxBytes)
            .flatMap { (image) -> Observable<String> in
                return ImageService.shared.userUpload(data: image.toBase64()).compactMap { $0.data }
        }
    }
    
    fileprivate func saveToLocal(data: Data, url: URL) -> Observable<Progress> {
        do {
            try data.write(to: url)
            let progress = Progress(totalUnitCount: 100)
            progress.setUserInfoObject(url, forKey: .imageURLKey)
            progress.setUserInfoObject(SourceImage.local, forKey: .imageSourceKey)
            return .just(progress)
        } catch {
            print(error)
            return .error(error)
        }
    }
    
    fileprivate func save(ref: ReferenceURL) {
        Repository<ReferenceURL, ReferenceURLObject>.shared.save(object: ref).subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func compress(image: UIImage, compressionQuality: CGFloat, maxBytes: Int) -> Observable<UIImage> {
        return Observable.just(image)
            .observeOn(SerialDispatchQueueScheduler(queue: .init(label: "compress_image"), internalSerialQueueName: "compress_image"))
            .flatMap { (image) -> Observable<UIImage> in
                guard let img = image.resizeAndCompress(compressionQuality, maxBytes: maxBytes) else { return .error(ServiceError(domain: "", code: -1, userInfo: ["message": "Image error"])) }
                return .just(img)
        }
            .observeOn(MainScheduler.asyncInstance)
    }
    
}

extension DefaultImageUsecase {
    enum SourceImage: Int {
        case local = 0
        case server = 1
    }
}

extension ProgressUserInfoKey {
    static let imageURLKey: ProgressUserInfoKey = .init("image_url_key")
    
    static let imageSourceKey: ProgressUserInfoKey = .init("image_source_key")
}
