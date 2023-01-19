//
//  PostContentCollectionViewCell.swift
//  gat
//
//  Created by jujien on 5/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import WordPressEditor
import Aztec
import RxSwift
import RxCocoa

class PostContentCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "postContent" }
    
    fileprivate let textView: TextView = .init(defaultFont: .systemFont(ofSize: 16.0, weight: .regular), defaultParagraphStyle: ParagraphStyle.default, defaultMissingImage: #imageLiteral(resourceName: "lazyImage"))
    
    let sizeCell: BehaviorRelay<CGSize> = .init(value: .zero)
    let content: BehaviorRelay<String> = .init(value: "")
    var updateCollection: ((CGSize) -> Void)?
    
    var downloadImage: ((URL) -> Observable<UIImage>)?
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async {
            self.setupUI()
        }
    }
  
    // MARK: - UI
    fileprivate func setupUI() {
        self.createTextView()
        self.contraintLayout()
    }
    
    fileprivate func createTextView() {
        self.textView.backgroundColor = .white
        self.textView.showsVerticalScrollIndicator = false
//        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.linkTextAttributes = [.font: UIFont.systemFont(ofSize: 16.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue]
        self.textView.textColor = .navy
        self.textView.clipsToBounds = false
        self.textView.isEditable = false
        self.textView.delegate = self
        self.textView.textAttachmentDelegate = self
        self.content.filter { !$0.isEmpty }.distinctUntilChanged().bind(onNext: self.textView.setHTML(_:)).disposed(by: self.disposeBag)
        self.content.filter { !$0.isEmpty }.distinctUntilChanged()
            .bind { [weak self] _ in
                self?.textView.isScrollEnabled = false

            }
            .disposed(by: self.disposeBag)
        self.setNeedsLayout()
        
        let textStorage = NSTextStorage(string: self.textView.text)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: self.bounds.size)
        layoutManager.addTextContainer(textContainer)
        self.textView.removeFromSuperview()
        let fixWidth = self.textView.frame.size.width
        let newSize = self.textView.sizeThatFits(CGSize(width: fixWidth, height: CGFloat.greatestFiniteMagnitude))
        self.textView.frame.size = CGSize(width: max(newSize.width,fixWidth), height: newSize.height)// remove original textView
        self.addSubview(self.textView)
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        let fixWidth = self.textView.frame.size.width
//        let newSize = self.textView.sizeThatFits(CGSize(width: fixWidth, height: CGFloat.greatestFiniteMagnitude))
//        self.textView.frame.size = CGSize(width: max(newSize.width,fixWidth), height: newSize.height)
//    }

    fileprivate func contraintLayout() {
        self.textView.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().inset(16.0)
            maker.trailing.equalToSuperview().inset(16.0)
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
    }
}

extension PostContentCollectionViewCell: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
//        self.sizeCell.accept(.init(width: self.sizeCell.value.width, height: self.textView.sizeThatFits(.init(width: self.sizeCell.value.width - 32.0, height: .infinity)).height))
//        self.updateCollection?(self.sizeCell.value)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
}

extension PostContentCollectionViewCell: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        self.downloadImage?(url)
            .observeOn(MainScheduler.instance)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { (_) in
                print("MAIN: \(Thread.isMainThread)")
            })
            .catchError({ (error) -> Observable<UIImage> in
                
            failure()
            return .empty()
        })
        .subscribe(onNext: success)
            .disposed(by: self.disposeBag)
    }
    
    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return nil
    }
    
    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage { #imageLiteral(resourceName: "lazyImage") }
    
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
        
    }
    
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        
    }
    
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        
    }
    
    
}

extension PostContentCollectionViewCell {
    
    fileprivate static let textAttachment = DefaultTextViewAttachment()
    
    class func size(content: String, in bounds: CGSize) -> CGSize {
        let textView: TextView = .init(defaultFont: .systemFont(ofSize: 16.0, weight: .regular), defaultParagraphStyle: ParagraphStyle.default, defaultMissingImage: #imageLiteral(resourceName: "lazyImage"))
//        textView.textContainer.lineFragmentPadding = 0
        textView.linkTextAttributes = [.font: UIFont.systemFont(ofSize: 16.0, weight: .semibold)]
        textView.textAttachmentDelegate = Self.textAttachment
        textView.setHTML(content)
        let size = textView.sizeThatFits(.init(width: bounds.width - 32.0, height: .infinity))
        return .init(width: bounds.width, height: size.height)
    }
}

fileprivate class DefaultTextViewAttachment: TextViewAttachmentDelegate {
    
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
    }
    
    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? { nil }
    
    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage { #imageLiteral(resourceName: "lazyImage") }
    
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
        
    }
    
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        
    }
    
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        
    }
    
    
}
