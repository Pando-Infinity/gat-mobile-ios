//
//  CreatePostPresenter.swift
//  gat
//
//  Created by jujien on 8/18/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftSoup
import Aztec

protocol CreatePostPresenter {
    var post: Observable<Post> { get }
    
    var getBodyIfNeeded: Observable<String> { get }
    
    var isReview: Bool { get }
    
    func showImagePicker()
    
    func upload(image: UIImage) -> Observable<Progress>
    
    func download(url: URL) -> Observable<UIImage>
    
    func removeImage(url: URL)
    
    func ratingHandler(_ value: Double)
    
    func openSetting(title: String, body: String, text: String)
        
    func openPreview(title: String, body: String, text: String)
    
    func back(title: String, body: String, text: String)
    
    func selected(mediaAttachment: MediaAttachment, in textView: TextView)
    
    func deselected(mediaAttachment: MediaAttachment, in textView: TextView)
    
}

struct SimpleCreatePostPresenter: CreatePostPresenter {
    
    var post: Observable<Post> { self.article.asObservable() }
    
    var isReview: Bool { self.article.value.isReview }
    
    var getBodyIfNeeded: Observable<String> { self.body.filter { !$0.isEmpty } }
        
    fileprivate let article: BehaviorRelay<Post>
    fileprivate let router: CreatePostRouter
    fileprivate let imageUsecase: ImageUsecase
    fileprivate let disposeBag = DisposeBag()
    fileprivate let body: BehaviorRelay<String> = .init(value: "")
    
    init(post: Post, imageUsecase: ImageUsecase, router: CreatePostRouter) {
        self.article = .init(value: post)
        self.imageUsecase = imageUsecase
        self.router = router
        self.getPost()
    }
    
    func showImagePicker() {
        self.router.showImagePicker()
    }
    
    func removeImage(url: URL) {
        guard let lastComponent = url.path.split(separator: "/").last else { return }
        let imageId = String(lastComponent)
        
        var article = self.article.value
        article.postImage.remove(imageId: imageId)
        if article.postImage.coverImage.isEmpty && article.postImage.thumbnailId.isEmpty && article.isReview {
            if let book = article.editionTags.first {
                article.postImage.coverImage = book.imageId
                article.postImage.thumbnailId = book.imageId
            }
        }
        self.article.accept(article)
    }
    
    func ratingHandler(_ value: Double) {
        var post = self.article.value
        post.rating = value
        self.article.accept(post)
    }
    
    func upload(image: UIImage) -> Observable<Progress> {
        return self.imageUsecase
            .imageProgress(image: image, compressionQuality: 0.8, maxBytes: 1000 * 1000)
            .do(onNext: { (progress) in
                guard let source = progress.userInfo[.imageSourceKey] as? DefaultImageUsecase.SourceImage, let url = progress.userInfo[.imageURLKey] as? URL, let lastComponent = url.path.split(separator: "/").last, source == .server else { return }
                let imageId = String(lastComponent)
                var article = self.article.value
                if article.postImage.coverImage.isEmpty {
                    article.postImage.coverImage = imageId
                } else {
                    if let book = article.editionTags.first, article.isReview {
                        if book.imageId == article.postImage.coverImage && article.postImage.bodyImages.isEmpty {
                            article.postImage.coverImage = imageId
                        }
                    }
                }
                if article.postImage.thumbnailId.isEmpty {
                    article.postImage.thumbnailId = imageId
                } else {
                    if let book = article.editionTags.first, article.isReview {
                        if book.imageId == article.postImage.thumbnailId && article.postImage.bodyImages.isEmpty {
                            article.postImage.thumbnailId = imageId
                        }
                    }
                }
                
                article.postImage.bodyImages.append(imageId)
                self.article.accept(article)
            })
    }
    
    func download(url: URL) -> Observable<UIImage> {
        guard !url.isFileURL else {
            if let data = try? Data(contentsOf: url) {
                return .from(optional: UIImage(data: data))
            }
            return .just(#imageLiteral(resourceName: "lazyImage"))
        }
        if let ref = Repository<ReferenceURL, ReferenceURLObject>.shared.get(predicateFormat: "serverURL = %@", args: [url.absoluteString]), let data = try? Data(contentsOf: ref.localURL), let image = UIImage(data: data) {
            return .just(image)
        }
        guard let lastComponent = url.path.split(separator: "/").last, let size = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems?.last?.value else { return .empty() }
        let imageId = String(lastComponent)
        return self.imageUsecase.download(imageId: imageId, size: SizeImage(rawValue: size) ?? .o)
            .compactMap { UIImage(data: $0) }
    }
    
    func openSetting(title: String, body: String, text: String) {
        var article = self.article.value
        article.title = title 
        article.intro = self.getIntro(in: text)
        article.body = body
        self.article.accept(article)
        self.router.showSetting(post: article).subscribe(onNext: self.article.accept).disposed(by: self.disposeBag)
    }
    
    func openPreview(title: String, body: String, text: String) {
        var article = self.article.value
        if article.isReview {
            if article.rating == 0 {
                self.router.showAlert(title: "ERROR_CONNECT_INTERNET_TITLE".localized(), message: "NOT_RATING_ALERT".localized())
                return
            }
            article.title = title
            article.intro = self.getIntro(in: text)
            article.body = self.proccess(body: body)
            if let book = article.editionTags.first, article.title.isEmpty {
                article.title = String(format: "BOOK_REVIEW_POST".localized(), book.title)
            }
            if article.body.isEmpty {
                let value = article.rating
                var text = ""
                if value == 1 {
                    text += "RATE_DONT_LIKE".localized()
                } else if value == 2 {
                    text += "RATE_OK".localized()
                } else if value == 3 {
                    text += "RATE_GOOD".localized()
                } else if value == 4 {
                    text += "RATE_GREAT".localized()
                } else {
                    text += "RATE_EXCELLENT".localized()
                }
                article.intro = text
                article.body = "<p>\(text)</p>"
            } else if !self.check(body: body) {
                self.router.showAlert(title: "ERROR_CONNECT_INTERNET_TITLE".localized(), message: "IMG_NOT_UPLOAD_TITLE".localized())
                return
            }
        } else {
            if title.isEmpty {
                self.router.showAlert(title: "ERROR_CONNECT_INTERNET_TITLE".localized(), message: "TITLE_POST_NOT_EMPTY".localized())
                return
            }
            if body.isEmpty {
                self.router.showAlert(title: "ERROR_CONNECT_INTERNET_TITLE".localized(), message: "CONTENT_POST_NOT_EMPTY".localized())
                return
            } else if self.checkEmty(body: body) {
                self.router.showAlert(title: "ERROR_CONNECT_INTERNET_TITLE".localized(), message: "CONTENT_POST_NOT_EMPTY".localized())
                return
            }
            else if !self.check(body: body) {
                self.router.showAlert(title: "ERROR_CONNECT_INTERNET_TITLE".localized(), message: "IMG_NOT_UPLOAD_TITLE_YET".localized())
                return
            } 
            if article.categories.isEmpty {
                self.router.showAlert(title: "ERROR_CONNECT_INTERNET_TITLE".localized(), message: "NOT_UPDATE_CATERGORY_POST".localized())
                return
            }
            
            guard !title.isEmpty, !body.isEmpty else { return }
            article.title = title
            article.intro = self.getIntro(in: text)
            article.body = self.proccess(body: body)
            
        }
        article.date.publishedDate = .init()
        article.state = .published
        self.article.accept(article)
        self.router.showPreview(post: article)
        .subscribe(onNext: self.article.accept).disposed(by: self.disposeBag)
    }
    
    func back(title: String, body: String, text: String) {
        self.router.alertBack { (item) in
            switch item {
            case .cancel: self.router.backScreen()
            case .continue: break
            case .draft: self.draft(title: title, body: body, text: text)
            }
        }
    }
    
    func selected(mediaAttachment: MediaAttachment, in textView: TextView) {
        if mediaAttachment.message == nil {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            mediaAttachment.message = NSAttributedString(string: "EDIT_ALERT_TITLE_REVIEWUSERPROFILE".localized(), attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .semibold), .foregroundColor: UIColor.navy, .paragraphStyle: paragraphStyle])
        }
        if let imageAttachment = mediaAttachment as? ImageAttachment, let url = imageAttachment.url {
            var actions: [UIAlertAction] = []
            if url.isFileURL {
                actions.append(.init(title: "REFRESH_URL_TITLE".localized(), style: .default, handler: { (_) in
                    guard let image = imageAttachment.image else { return }
                    self.refreshUpload(image: image, attachment: imageAttachment, in: textView)
                }))
                mediaAttachment.overlayImage = #imageLiteral(resourceName: "sync-alt")
            } else {
                mediaAttachment.overlayImage = #imageLiteral(resourceName: "Pencil")
            }
            actions.append(.init(title: "REMOVE_ALERT_TITLE_REVIEWUSERPROFILE".localized(), style: .destructive, handler: { (_) in
                textView.remove(attachmentID: mediaAttachment.identifier)
                self.removeImage(url: url)
                textView.refresh(mediaAttachment)
            }))

            actions.append(.init(title: "CANCEL_ALERT_TITLE_REVIEWUSERPROFILE".localized(), style: .cancel, handler: { _ in
                self.resetMediaAttachmentOverlay(mediaAttachment: imageAttachment)
                textView.refresh(mediaAttachment)
            }))
            self.router.showOptionAlert(mediaAttachment: imageAttachment, actions: actions)
        }
    }
    
    func deselected(mediaAttachment: MediaAttachment, in textView: TextView) {
        if let imageAttachment = mediaAttachment as? ImageAttachment, let url = imageAttachment.url, !url.isFileURL {
            mediaAttachment.message = nil
        }
        mediaAttachment.overlayImage = nil
        textView.refresh(mediaAttachment)
    }
}


extension SimpleCreatePostPresenter {
    
    fileprivate func getPost() {
        guard self.article.value.id != .zero && self.article.value.body.isEmpty else { return }
        PostService.shared.post(id: self.article.value.id)
            .catchError { (error) -> Observable<Post> in
                self.router.showAlert(error: error)
                return .empty()
            }
            .do(onNext: { self.body.accept($0.body) })
            .subscribe(onNext: self.article.accept)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func refreshUpload(image: UIImage, attachment: ImageAttachment, in textView: TextView) {
        attachment.message = .init(string: "LOADING_MESSEAGE".localized(), attributes: [.font: UIFont.systemFont(ofSize: 15.0, weight: .semibold), .foregroundColor: UIColor.white])
        textView.refresh(attachment)
        self.upload(image: image)
            .catchError { (error) -> Observable<Progress> in
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                print(error.localizedDescription)
                attachment.message = NSAttributedString(string: "UPLOAD_ERROR_POST_IMG".localized(), attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .semibold), .paragraphStyle: paragraphStyle, .foregroundColor: UIColor.white])
                attachment.overlayImage = #imageLiteral(resourceName: "sync-alt")
                textView.refresh(attachment)
                return .empty()
        }
        .subscribe(onNext: { (progress) in
            attachment.overlayImage = nil
            attachment.message = nil
            guard let source = progress.userInfo[.imageSourceKey] as? DefaultImageUsecase.SourceImage, source == .server else { return }
            if progress.fractionCompleted >= 1 {
                attachment.progress = nil
                if let url = progress.userInfo[.imageURLKey] as? URL, let attachmentRange = textView.textStorage.ranges(forAttachment: attachment).first {
                    textView.replaceWithImage(at: attachmentRange, sourceURL: url, placeHolderImage: image).alignment = .center
                    textView.removeLink(inRange: attachmentRange)
                    textView.selectedRange = .init(location: textView.attributedText.length, length: 0)
                }
            } else {
                attachment.progress = progress.fractionCompleted
            }
            textView.refresh(attachment, overlayUpdateOnly: true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func resetMediaAttachmentOverlay(mediaAttachment: MediaAttachment) {
        
        mediaAttachment.message = nil
        mediaAttachment.overlayImage = nil
    }
    
    fileprivate func draft(title: String, body: String, text: String) {
        if !self.check(body: body) {
            self.router.showAlert(title: "ERROR_CONNECT_INTERNET_TITLE".localized(), message: "IMG_NOT_UPLOAD_TITLE_YET".localized())
            return
        }
        var article = self.article.value
        article.title = title
        article.intro = self.getIntro(in: text)
        article.body = self.proccess(body: body)
        article.state = .draft
        PostService.shared.update(post: article)
            .catchError { (error) -> Observable<Post> in
                self.router.showAlert(error: error)
                return .empty()
        }
        .subscribe(onNext: { (_) in
            self.router.backScreen()
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getIntro(in text: String) -> String {
        let substring = text.replacingOccurrences(of: "\n", with: "").split(separator: " ").map { String($0) }
        guard substring.count > 175 else { return text }
        return substring[0..<175].joined(separator: " ")
    }
    
    fileprivate func proccess(body: String) -> String {
        var copy = self.replaceWrong(body: body)
        copy = self.replaceSpaceHTML(body: copy)
        let doc = try? SwiftSoup.parse(body)
        try? doc?.select("img").forEach({ (element) in
            let outer = (try? element.outerHtml()) ?? ""
            if let value = try? element.attr("src"), let url = URL(string: value), url.isFileURL {
                copy = copy.replacingOccurrences(of: outer, with: "")
            }
        })
        return copy
    }
    
    //fix error aztec library exporting wrong html
    fileprivate func replaceWrong(body: String) -> String {
        var copy = body
        let doc = try? SwiftSoup.parse(body)
        try? doc?.select("li").forEach({ (e) in
            let outer = (try? e.outerHtml()) ?? ""
            if e.parent()?.tag().getName() != "ul" {
                let replace = outer.replacingOccurrences(of: "li", with: "p")
                copy = copy.replacingOccurrences(of: outer, with: replace)
            }
        })
        return copy
    }
    
    fileprivate func replaceSpaceHTML(body: String) -> String {
        var words = body.components(separatedBy: "\n")
        for i in (0..<words.count-1).reversed(){
            if words[i] == "<p></p>" {
                words.remove(at: i)
            } else {
                break
            }
        }
        
        return words.joined(separator: "\n")
    }
    
    func checkEmty(body: String) -> Bool {
        let doc = try? SwiftSoup.parse(body)
        let resevred = try? doc!.select("p").reversed()
        let item = resevred!.firstIndex(where: { try! $0.text() != "" })
        
        let reservedImg = try? doc!.select("img").reversed()
        let itemImg = reservedImg!.firstIndex(where: {try! $0.attr("src") != ""})
        
        return (item == nil) && (itemImg == nil)
    }
    
    func check(body: String) -> Bool {
        do {
            let doc = try SwiftSoup.parse(body)
            let result = try doc.select("img").first(where: { (element) -> Bool in
                let value = try element.attr("src")
                if let url = URL(string: value) {
                    return url.isFileURL
                }
                return false
            })
            return result == nil
        } catch {
            return false
        }
    }
    
    
}
