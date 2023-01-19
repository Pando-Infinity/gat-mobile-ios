//
//  CommentPostCollectionViewCell.swift
//  gat
//
//  Created by jujien on 5/5/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import InputBarAccessoryView
import Lottie

class CommentPostCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "commentPostCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var contentTextView: InputTextView!
    @IBOutlet weak var contentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var numberHeartButton: UIButton!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var showMoreReplyButton:UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var seperateView: UIView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var bookCollectionView: UICollectionView!
    @IBOutlet weak var replyTopHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var replyTopLowConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionTopHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionTopLowConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bookTopConstrait: NSLayoutConstraint!
    fileprivate let disposeBag = DisposeBag()
    
    let comment: BehaviorRelay<WrappedCommentPostAttributes?> = .init(value: nil)
    
    var replyHandler: ((CommentPost) -> Void)?
    var editHandler: ((CommentPost, NSAttributedString) -> Void)?
    var removeHandler: ((CommentPost) -> Void)?
    var reactionCommentHandler: ((CommentPost,Post.Reaction,Int)->Void)?
    
    var nextReplyHandler: ((CommentPost) -> Void)?
    
    var openBookDetail: ((BookInfo) -> Void)?
    var openProfile: ((Profile) -> Void)?
    
    var openListUserReaction: ((CommentPost) -> Void)?
    
    fileprivate let book: BehaviorRelay<BookInfo?> = .init(value: nil)
    fileprivate let user: BehaviorRelay<Profile?> = .init(value: nil)
    fileprivate var reactionCount = 0
    var userReactCount = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 13.0, *) {
            self.bookTopConstrait.priority = .required
        } else {
            self.bookTopConstrait.priority = .defaultHigh
        }
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.replyButton.setTitle("REPLY_COMMENT_TITLE".localized(), for: .normal)
        self.editButton.setTitle("EDIT_COMMENT_TITLE".localized(), for: .normal)
        self.deleteButton.setTitle("DELETE_COMMENT_TITLE".localized(), for: .normal)
        self.layer.masksToBounds = false
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
        self.comment.compactMap { $0?.comment.isReaction }.map { $0 ? #imageLiteral(resourceName: "h") : #imageLiteral(resourceName: "heart") }.bind(to: self.heartButton.rx.image()).disposed(by: self.disposeBag)
        self.comment.compactMap { $0?.comment.summary.reactCount }.map { String(format:"NUMBER_REACTION_POST_TITLE".localized(),$0) }.bind(to: self.numberHeartButton.rx.title()).disposed(by: self.disposeBag)

        self.setupCommentCollectionView()
        self.setupBookCollectionView()
        self.setupShowMoreReply()
    }
    
    fileprivate func setupShowMoreReply() {
        let share = self.comment.compactMap { $0?.comment }.map { $0.replies.count == $0.summary.replyCount }.share()
        share.bind(to: self.showMoreReplyButton.rx.isHidden).disposed(by: self.disposeBag)
        share.bind { [weak self] (value) in
            self?.collectionTopHighConstraint.priority = value ? .defaultLow : .defaultHigh
            self?.collectionTopLowConstraint.priority = value ? .defaultHigh: .defaultLow
            self?.layoutIfNeeded()
        }
        .disposed(by: self.disposeBag)
        
        self.comment.compactMap { $0?.comment }.map { (comment) -> String in
            guard comment.summary.replyCount > comment.replies.count else { return "" }
            if (comment.summary.replyCount - comment.replies.count) % 3 == 0 {
                return String(format: "SHOW_MORE_REPLY_TITLE".localized(), 3)
            }
            return String(format: "SHOW_MORE_REPLY_TITLE".localized(), comment.summary.replyCount - comment.replies.count)
        }
        .bind(to: self.showMoreReplyButton.rx.title(for: .normal))
        .disposed(by: self.disposeBag)
    }
    
    func hidenBtnShowMoreReply(hide: Bool){
        self.showMoreReplyButton.isHidden = hide
    }
    
    fileprivate func setupTextView() {
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
            .compactMap { (comment) -> NSAttributedString? in
                return comment?.contentAttributes
        }
            .bind(onNext: { [weak self] (attrs) in
                self?.contentTextView.attributedText = attrs
                guard let size = self?.frame.size else { return }
                let padding: CGFloat = 16.0
                let spacing: CGFloat = 8.0
                let heartButtonWidth: CGFloat = 35.0
                guard let contentSize = self?.contentTextView?.sizeThatFits(.init(width: size.width - (padding - spacing / 2.0) - spacing - heartButtonWidth - padding, height: .infinity)) else { return }
                self?.contentHeightConstraint.constant = contentSize.height
            })
        .disposed(by: self.disposeBag)

    }
    
    fileprivate func setupCommentCollectionView() {
        self.collectionView.isScrollEnabled = false
        self.comment.compactMap { $0?.replies }.map { $0.isEmpty }.bind(to: self.collectionView.rx.isHidden, self.seperateView.rx.isHidden).disposed(by: self.disposeBag)
        
        self.collectionView.register(UINib(nibName: CommentPostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: CommentPostCollectionViewCell.identifier)
        self.collectionView.layer.masksToBounds = false
        self.comment.compactMap { $0?.replies }
            .bind(to: self.collectionView.rx.items(cellIdentifier: CommentPostCollectionViewCell.identifier, cellType: CommentPostCollectionViewCell.self)) { [weak self] (index, comment, cell) in
                cell.replyHandler = self?.replyHandler
                cell.removeHandler = self?.removeHandler
                cell.editHandler = self?.editHandler
                cell.reactionCommentHandler = self?.reactionCommentHandler
                cell.openProfile = self?.openProfile
                cell.openBookDetail = self?.openBookDetail
                cell.openListUserReaction = self?.openListUserReaction
                cell.comment.accept(comment)

        }.disposed(by: self.disposeBag)

        self.collectionView.delegate = self
    }
    
    fileprivate func setupBookCollectionView() {
        self.comment.compactMap { $0?.comment.editionTags }.map { $0.isEmpty }.bind { [weak self] (value) in
            self?.replyTopLowConstraint.priority = value ? .init(rawValue: 850) : .defaultLow
            self?.replyTopHighConstraint.priority = value ? .defaultLow : .init(rawValue: 850)
            self?.bookCollectionView.isHidden = value
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
    
    fileprivate func showAnimation() {
        let animationView = AnimationView(name: "heart")
        animationView.backgroundColor = .clear
        animationView.contentMode = .scaleAspectFit
        self.insertSubview(animationView, belowSubview: self.heartButton)
        animationView.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(self.heartButton.snp.centerX)
            maker.bottom.equalTo(self.heartButton.snp.bottom).offset(-15.0)
            maker.height.equalTo(200)
            maker.width.equalTo(45.0)
        }

        animationView.play { (status) in
            animationView.removeFromSuperview()
        }
    }
    
    fileprivate func showReactionCount() {
        let view = UIView()
        view.backgroundColor = .grapefruit
        
        self.addSubview(view)
        view.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(self.heartButton.snp.centerX)
            maker.width.equalTo(view.snp.height)
            maker.width.equalTo(35.0)
            maker.bottom.equalTo(self.heartButton.snp.top).offset(-8.0)
        }
        view.layer.masksToBounds = true
        view.cornerRadius(radius: 17.5)
        view.alpha = .zero

        let label = UILabel()
        if self.userReactCount > UserReaction.MAX {
            self.userReactCount = UserReaction.MAX
        }
        label.text = "+\(self.userReactCount)"
        label.textColor = .white
        label.font = .systemFont(ofSize: 12.0, weight: .semibold)
        label.textAlignment = .center
        view.addSubview(label)
        
        label.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
        
        UIView.animate(withDuration: 0.15, animations: {
            view.alpha = 1.0
        }) { (_) in
            UIView.animate(withDuration: 0.5, animations: {
                view.alpha = .zero
            }) { (_) in
                view.removeFromSuperview()
            }
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        layout.zIndex = 100
        return layout
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layoutAttributes.zIndex = 100
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.replyEvent()
        self.editEvent()
        self.removeEvent()
        self.reactCommentEvent()
        self.eventBtnShowMoreReply()
        self.bookEvent()
        self.userEvent()
        self.listUserReactionEvent()
        self.textViewEvent() 
    }
    
    fileprivate func reactCommentEvent() {
        var timer: Timer?
        
        self.comment.subscribe { (wrapComment) in
            guard let comment = wrapComment?.comment else {return}
            self.userReactCount = comment.userReaction.reactCount
        } onError: { (_) in
            
        } onCompleted: {
            
        } onDisposed: {
            
        }.disposed(by: self.disposeBag)

        
        self.heartButton.rx.tap.asObservable()
            .do (onNext: { [weak self] (_) in
                guard Session.shared.isAuthenticated else {
                    HandleError.default.loginAlert()
                    return
                }
                self?.showAnimation()
                self?.heartButton.setImage(#imageLiteral(resourceName: "h"), for: [])
                guard let cell = self, cell.userReactCount < UserReaction.MAX else {
                    self?.showReactionCount()
                    return
                }
                cell.userReactCount += 1
                cell.reactionCount += 1
                self?.showReactionCount()
                var comment = cell.comment.value?.comment
                comment?.summary.reactCount += cell.reactionCount
                cell.numberHeartButton.setTitle(String(format:"NUMBER_REACTION_POST_TITLE".localized(),comment?.summary.reactCount ?? 0), for: [])
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
                if self!.userReactCount <= UserReaction.MAX {
                    self?.reactionCommentHandler?(comment, .love, self?.reactionCount ?? 0)
                }
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
                guard var comment = cell.comment.value?.comment else { return }
                if comment.content.last == "\n" {
                    comment.content.removeLast()
                }
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
    
    func eventBtnShowMoreReply(){
        self.showMoreReplyButton.rx.tap
            .do(onNext: {  (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { _ in Session.shared.isAuthenticated }
            .withLatestFrom(self.comment.compactMap { $0 })
            .bind { [weak self] (comment) in
                self?.nextReplyHandler?(comment.comment)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func textViewEvent() {
        self.contentTextView.rx.tapGesture().when(.recognized)
            .subscribe { [weak self] (gesture) in
                guard let contentTextView = self?.contentTextView else { return }
                var location = gesture.location(in: contentTextView)
                location.x -= contentTextView.textContainerInset.left
                location.y -= contentTextView.textContainerInset.top

                let characterIndex = contentTextView.layoutManager.characterIndex(for: location, in: contentTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
                guard characterIndex < contentTextView.textStorage.length else { return  }
                if let attributeValue = contentTextView.attributedText?.attribute(.autocompletedContext, at: characterIndex, effectiveRange: nil) as? [String: Any], let url = attributeValue["url"] as? URL {
                    self?.textView(contentTextView, shouldInteractWith: url, context: attributeValue)
                }
            } onError: { (_) in
                
            } onCompleted: {
                
            } onDisposed: {
                
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func bookEvent() {
        Observable
            .of(
                self.bookCollectionView.rx.modelSelected(BookInfo.self).asObservable(),
                self.book.compactMap { $0 }
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
                self.user.compactMap { $0 }
            )
        .merge()
        .bind { [weak self] user in
            self?.openProfile?(user)
        }
        .disposed(by: self.disposeBag)

            
    }
    
    fileprivate func listUserReactionEvent() {
        self.numberHeartButton.rx.tap.subscribe { [weak self] (_) in
            guard let comment = self?.comment.value?.comment else { return }
            self?.openListUserReaction?(comment)
        }
        .disposed(by: self.disposeBag)

    }
}

extension CommentPostCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case self.collectionView:
            guard let comments = self.comment.value?.replies, !comments.isEmpty else { return .zero }
            return ReplyCommentPostCollectionViewCell.size(comment: comments[indexPath.row], in: collectionView.bounds.size)
        case self.bookCollectionView: return .init(width: self.frame.width - 32.0, height: self.bookHeightConstraint.constant)
        default: return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}

extension CommentPostCollectionViewCell: InputTextViewDelegate {
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

extension CommentPostCollectionViewCell {
    
    class func size(comment: WrappedCommentPostAttributes, in bounds: CGSize) -> CGSize {
        let heightOwnerInfo: CGFloat = 32.0
        let padding: CGFloat = 16.0
        let spacing: CGFloat = 8.0
        let heartButtonWidth: CGFloat = 35.0
        let replyHeight: CGFloat = 20.0
        let seperateWidth: CGFloat = 1.0
        let bookHeight: CGFloat = 98.0
        let showMoreHeight: CGFloat = 32.0

        let content = UITextView()
        content.textContainerInset = .zero
        content.contentInset = .zero
        content.attributedText = comment.contentAttributes
        let contentSize = content.sizeThatFits(.init(width: bounds.width - (padding - spacing / 2.0) - spacing - heartButtonWidth - padding, height: .infinity))
        
        let widthBoundSubComment: CGFloat = bounds.width - padding - seperateWidth
        let heightSubComment: CGFloat = comment.replies.compactMap { CommentPostCollectionViewCell.size(comment: $0, in: .init(width: widthBoundSubComment, height: .infinity)).height }.reduce(0.0, +)
        var height = heightOwnerInfo + spacing + contentSize.height

        if !comment.comment.editionTags.isEmpty {
            height += spacing + bookHeight + spacing + replyHeight
        } else {
            height += spacing + replyHeight
        }

        if comment.comment.replies.isEmpty || comment.replies.count == comment.comment.summary.replyCount {
            height += spacing
        } else {
            height += spacing + showMoreHeight + spacing
        }
        if heightSubComment != .zero {
            height += heightSubComment + spacing
        }
        return .init(width: bounds.width, height: height)
    }
}
