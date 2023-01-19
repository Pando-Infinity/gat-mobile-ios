//
//  ReplyCommentPostCollectionViewCell.swift
//  gat
//
//  Created by jujien on 11/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import InputBarAccessoryView

class ReplyCommentPostCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "replyCommentPostCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var contentTextView: InputTextView!
    @IBOutlet weak var contentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var bookCollectionView: UICollectionView!
    @IBOutlet weak var replyTopHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var replyTopLowConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookHeightConstraint: NSLayoutConstraint!
    
    
    fileprivate let disposeBag = DisposeBag()
    
    let comment: BehaviorRelay<WrappedCommentPostAttributes?> = .init(value: nil)
    let sizeCell: BehaviorRelay<CGSize> = .init(value: .zero)
    
    var replyHandler: ((CommentPost) -> Void)?
    var editHandler: ((CommentPost, NSAttributedString) -> Void)?
    var removeHandler: ((CommentPost) -> Void)?
    var reactionCommentHandler: ((CommentPost,Post.Reaction,Int)->Void)?
        
    var openBookDetail: ((BookInfo) -> Void)?
    var openProfile: ((Profile) -> Void)?
    
    fileprivate let book: BehaviorRelay<BookInfo?> = .init(value: nil)
    fileprivate let user: BehaviorRelay<Profile?> = .init(value: nil)
    fileprivate var reactionCount = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
        // Initialization code
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.replyButton.setTitle("REPLY_COMMENT_TITLE".localized(), for: .normal)
        self.editButton.setTitle("EDIT_COMMENT_TITLE".localized(), for: .normal)
        self.comment.compactMap { $0?.comment }.map { $0.user.id == Session.shared.user?.id }.map { !$0 }.bind(to: self.editButton.rx.isHidden, self.deleteButton.rx.isHidden)
            .disposed(by: self.disposeBag)
        self.imageView.contentMode = .scaleAspectFill
        self.comment.map { $0?.comment.user.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.comment.compactMap { $0?.comment.user.imageId }
            .map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }
        .bind(to: self.imageView.rx.url(placeholderImage: DEFAULT_USER_ICON))
        .disposed(by: self.disposeBag)
        self.imageView.circleCorner()

        self.comment.compactMap { $0?.comment }.map { AppConfig.sharedConfig.calculatorDay(date: $0.lastUpdate) }.bind(to: self.dateLabel.rx.text).disposed(by: self.disposeBag)
        
        self.setupTextView()
        self.comment.compactMap { $0?.comment.summary.reactCount }.map { "\($0)" }.bind(to: self.numberLabel.rx.text).disposed(by: self.disposeBag)

        self.setupBookCollectionView()
    }
    
    
    fileprivate func setupTextView() {
//        self.textView.textColor = .navy
        self.contentTextView.backgroundColor = .clear
        self.contentTextView.contentInset = .zero
        self.contentTextView.isEditable = false
        self.contentTextView.isSelectable = true
        self.contentTextView.delegate = self
        self.contentTextView.textContainerInset = .zero
        self.contentTextView.contentInset = .zero
        self.contentTextView.showsVerticalScrollIndicator = false
        self.contentTextView.showsHorizontalScrollIndicator = false
        self.comment
            .observeOn(MainScheduler.asyncInstance)
            .compactMap { [weak self] (comment) -> NSAttributedString? in
                return comment?.contentAttributes
//                guard let comment = comment else { return nil }
//                let data = Data(comment.content.utf8)
//                guard let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) else { return nil }
//
//                let atrs = NSMutableAttributedString(string: attributedString.string, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: UIColor.navy])
//                var context: [String: Any] = [:]
//                let web: String = AppConfig.sharedConfig.get("web_url")
//                comment.usersTags.forEach { (profile) in
//                    context["id"] = profile.id
//                    context["prefix"] = CommentPost.USER_TAG_PREFIX
//                    context["url"] = URL(string: web + "users/\(profile.id)")
//                    #if DEBUG
//                    let range = (attributedString.string as NSString).range(of: profile.name.replacingOccurrences(of: "_test", with: ""))
//                    #else
//                    let range = (attributedString.string as NSString).range(of: profile.name)
//                    #endif
//                    atrs.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue, .autocompleted: true, .autocompletedContext: context], range: range)
//                }
//
//                comment.editionTags.forEach { (book) in
//                    context["id"] = book.editionId
//                    context["prefix"] = CommentPost.BOOK_TAG_PREFIX
//                    context["url"] = URL(string: web + "books/\(book.editionId)")
//                    let range = (attributedString.string as NSString).range(of: book.title)
//                    atrs.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue, .autocompleted: true, .autocompletedContext: context], range: range)
//                }
//                return atrs

//            guard let comment = comment, let textView = self?.textView else { return nil }
//            textView.setHTML(comment.content)
//            var attrs = textView.attributedText.copy() as! NSAttributedString
//            attrs.enumerateAttribute(.link, in: .init(location: 0, length: textView.attributedText.length), options: .reverse) { (_, subrange, stop) in
//                let string = attrs.string
//                guard let range = Range(subrange, in: string) else { return }
//                let substring = String(string[range])
//                if let url = textView.attributedText.attribute(.link, at: subrange.location, effectiveRange: nil) as? URL {
//                    var context: [String: Any] = ["url": url]
//                    let web: String = AppConfig.sharedConfig.get("web_url") //https://gatbook.org/
//                    let components = url.absoluteString.replacingOccurrences(of: web, with: "").split(separator: "/")
//                    if let id = components.compactMap({ Int($0) }).first {
//                        context["id"] = id
//                        if components.contains("users") {
//                            context["prefix"] = CommentPost.USER_TAG_PREFIX
//                        } else {
//                            context["prefix"] = CommentPost.BOOK_TAG_PREFIX
//                        }
//                        attrs = attrs.replacingCharacters(in: subrange, with: .init(string: substring, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue, .autocompleted: true, .autocompletedContext: context]))
//                    }
//                }
//            }
//            return attrs
        }
        .bind(to: self.contentTextView.rx.attributedText)
        .disposed(by: self.disposeBag)
        Observable.combineLatest(self.comment.compactMap { $0 }, self.sizeCell.asObservable())
            .filter { $0.1 != .zero }
            .compactMap { [weak self] (comment, sizeCell) -> CGSize? in
                let padding: CGFloat = 16.0
                let spacing: CGFloat = 8.0
                let heartWidth: CGFloat = 24.0
                return self?.contentTextView.sizeThatFits(.init(width: sizeCell.width - (padding - spacing / 2.0) - spacing - heartWidth - padding, height: .infinity))
            }
            .map { $0.height }
            .bind(to: self.contentHeightConstraint.rx.constant)
            .disposed(by: self.disposeBag)

    }
    
    fileprivate func setupBookCollectionView() {
        self.comment.compactMap { $0?.comment.editionTags }.map { $0.isEmpty }.bind { [weak self] (value) in
            self?.bookCollectionView.isHidden = value
            self?.replyTopLowConstraint.priority = value ? .defaultHigh : .defaultLow
            self?.replyTopHighConstraint.priority = value ? .defaultLow : .defaultHigh
        }
        .disposed(by: self.disposeBag)
        
        self.bookCollectionView.register(UINib.init(nibName: BookDetailInPostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookDetailInPostCollectionViewCell.identifier)
        
        
        self.comment.compactMap { $0?.comment.editionTags }.filter { !$0.isEmpty }.bind(to: self.bookCollectionView.rx.items(cellIdentifier: BookDetailInPostCollectionViewCell.identifier, cellType: BookDetailInPostCollectionViewCell.self)) { [weak self] (index, book, cell) in
            cell.book.accept(book)
            cell.titleTopConstraint.constant = 0.0
            cell.titleLabel.font = .systemFont(ofSize: 14.0, weight: .semibold)
            cell.authorLabel.font = .systemFont(ofSize: 12.0, weight: .regular)
            if let c = self {
                cell.sizeCell.accept(.init(width: c.bookCollectionView.frame.width - 32.0, height: c.bookHeightConstraint.constant))
            }
        }.disposed(by: self.disposeBag)
        self.bookCollectionView.delegate = self
        
        
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell.value != .zero {
            attributes.frame.size = self.sizeCell.value
        }
        return attributes
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.replyEvent()
        self.editEvent()
        self.removeEvent()
        self.reactCommentEvent()
        self.bookEvent()
        self.userEvent()
    }
    
    fileprivate func reactCommentEvent() {
        var timer: Timer?
        self.heartButton.rx.tap.asObservable()
            .do (onNext: { [weak self] (_) in
                guard Session.shared.isAuthenticated else {
                    HandleError.default.loginAlert()
                    return
                }
                guard let cell = self, cell.reactionCount < UserReaction.MAX else { return }
                cell.reactionCount += 1
                var comment = cell.comment.value?.comment
                comment?.summary.reactCount += cell.reactionCount
                cell.numberLabel.text = "\(comment?.summary.reactCount ?? 0)"
            })
            .filter { _ in Session.shared.isAuthenticated }
            .flatMap { (_) -> Observable<Timer> in
                timer?.invalidate()
                timer = nil
                return Observable<Timer>.create { (observer) -> Disposable in
                    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (timer) in
                        observer.onNext(timer)
                    })
                    return Disposables.create {
                        timer?.invalidate()
                        timer = nil
                    }
                }
            }
            .bind { [weak self] (_) in
                guard let cell = self, let comment = cell.comment.value?.comment else { return }
                self?.reactionCommentHandler?(comment, .love, self?.reactionCount ?? 0)
                self?.reactionCount = 0
            }
            .disposed(by: self.disposeBag)


    }
    
    fileprivate func replyEvent() {
        self.replyButton.rx.tap.asObservable()
            .do(onNext: {  (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { _ in Session.shared.isAuthenticated }
            .subscribe(onNext: { [weak self] (_) in
            guard let value = self?.comment.value else { return }
                let id = value.comment.parentCommentId != nil ? value.comment.parentCommentId! : value.comment.id
                let comment = CommentPost(id: id, post: value.comment.post, editionTags: [], usersTags: [value.comment.user], content: "", user: value.comment.user, lastUpdate: .init(), summary: .init(reactCount: 0, replyCount: 0))
            self?.replyHandler?(comment)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func editEvent() {
        self.editButton.rx.tap
            .do(onNext: {  (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { _ in Session.shared.isAuthenticated }
            .withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (cell) in
                guard let comment = cell.comment.value?.comment else { return }
                cell.editHandler?(comment, cell.contentTextView.attributedText)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func removeEvent() {
        self.deleteButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (cell) in
                guard let comment = cell.comment.value?.comment else { return }
                cell.removeHandler?(comment)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func bookEvent() {
        Observable
            .of(
                self.bookCollectionView.rx.modelSelected(BookInfo.self).asObservable(),
                self.book.compactMap { $0 }.distinctUntilChanged({ $0.editionId == $1.editionId })
            )
            .merge()
            .bind { [weak self] book in
                self?.openBookDetail?(book)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func userEvent() {
        let gesture = Observable
            .of(
                self.imageView.rx.tapGesture().when(.recognized),
                self.nameLabel.rx.tapGesture().when(.recognized)
            )
            .merge()
            .withLatestFrom(self.comment.compactMap { $0 })
            .map { $0.comment.user }
        
        Observable
            .of(
                gesture,
                self.user.compactMap { $0 }.distinctUntilChanged({ $0.id == $1.id })
            )
        .merge()
        .bind { [weak self] user in
            self?.openProfile?(user)
        }
        .disposed(by: self.disposeBag)
    }

}

extension ReplyCommentPostCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: self.frame.width - 32.0, height: self.bookHeightConstraint.constant)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}

extension ReplyCommentPostCollectionViewCell: InputTextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, context: [String: Any]) -> Bool {
        guard let prefix = context["prefix"] as? String, let id = context["id"] as? Int else { return false }
        if prefix == CommentPost.USER_TAG_PREFIX {
            let profile = Profile()
            profile.id = id
            self.user.accept(profile)
        } else {
            let book = BookInfo()
            book.editionId = id
            self.book.accept(book)
        }
        return false
    }
}

extension ReplyCommentPostCollectionViewCell {
    
//    fileprivate static let textView = TextView(defaultFont: .systemFont(ofSize: 14.0), defaultMissingImage: #imageLiteral(resourceName: "lazyImage"))
    
    
    class func size(comment: WrappedCommentPostAttributes, in bounds: CGSize) -> CGSize {
        let heightOwnerInfo: CGFloat = 32.0
        let padding: CGFloat = 16.0
        let spacing: CGFloat = 8.0
        let heartButtonWidth: CGFloat = 35.0
        let replyHeight: CGFloat = 20.0
        let bookHeight: CGFloat = 98.0

        let content = UITextView()
        content.textContainerInset = .zero
        content.contentInset = .zero
        content.attributedText = comment.contentAttributes
//        let textView = TextView(defaultFont: .systemFont(ofSize: 14.0), defaultMissingImage: #imageLiteral(resourceName: "lazyImage"))
//        textView.setHTML(comment.content)
//        var attrs = textView.attributedText.copy() as! NSAttributedString
//        attrs.enumerateAttribute(.link, in: .init(location: 0, length: textView.attributedText.length), options: .reverse) { (_, subrange, stop) in
//            let string = attrs.string
//            guard let range = Range(subrange, in: string) else { return }
//            let substring = String(string[range])
//            if let url = textView.attributedText.attribute(.link, at: subrange.location, effectiveRange: nil) as? URL {
////                var context: [String: Any] = ["url": url]
//                let web: String = AppConfig.sharedConfig.get("web_url") //https://gatbook.org/
//                let components = url.absoluteString.replacingOccurrences(of: web, with: "").split(separator: "/")
//                if components.compactMap({ Int($0) }).first != nil {
//
//                    attrs = attrs.replacingCharacters(in: subrange, with: .init(string: substring, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)]))
//                }
//            }
//        }
//        content.attributedText = attrs

//        let data = Data(comment.content.utf8)
//        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) {
//            let atrs = NSMutableAttributedString(string: attributedString.string, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular)])
//            comment.usersTags.forEach { (profile) in
//                #if DEBUG
//                let range = (attributedString.string as NSString).range(of: profile.name.replacingOccurrences(of: "_test", with: ""))
//                #else
//                let range = (attributedString.string as NSString).range(of: profile.name)
//                #endif
//                atrs.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: range)
//            }
//
//            comment.editionTags.forEach { (book) in
//                let range = (attributedString.string as NSString).range(of: book.title)
//                atrs.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: range)
//            }
//            content.attributedText = atrs
//        }
        let contentSize = content.sizeThatFits(.init(width: bounds.width - (padding - spacing / 2.0) - spacing - heartButtonWidth - padding, height: .infinity))
        
        var height = heightOwnerInfo + spacing + contentSize.height

        if !comment.comment.editionTags.isEmpty {
            height += spacing + bookHeight + spacing + replyHeight
        } else {
            height += spacing + replyHeight
        }

        height += spacing
        
        return .init(width: bounds.width, height: height)
    }
}
