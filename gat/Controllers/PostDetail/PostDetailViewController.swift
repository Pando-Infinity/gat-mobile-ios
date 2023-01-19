//
//  PostDetailViewController.swift
//  gat
//
//  Created by jujien on 5/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import InputBarAccessoryView
import Aztec
import SnapKit

class PostDetailViewController: UIViewController {
    
    class var identifier: String { Self.className }
    
    class var segueIdentifier: String { "showPostDetail" }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var collectionBottomConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override var inputAccessoryView: UIView? { Session.shared.isAuthenticated ? self.inputBarView : nil }
    
    override var canBecomeFirstResponder: Bool { true }
    
    let inputBarView: CommentInputBar = .init()
    
    var commentFirstResponder: Bool = false
    
    var presenter: PostDetailPresenter!
    fileprivate var datasource: RxCollectionViewSectionedReloadDataSource<SectionModel<PostDetailItem, Any>>!
    fileprivate let disposeBag = DisposeBag()
    fileprivate var decorator: DecoratorAutoComplete!
    fileprivate var autoCompleteManager: AutoCompleteInput!
    fileprivate let contentPostSize: BehaviorRelay<CGSize> = .init(value: UIScreen.main.bounds.size)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    fileprivate func giveDonate(profile: Profile, amount: Double) {
        do {
            try WalletService.shared.donate(user: profile, amount: amount)
            self.showConfirm(profile: profile, amount: amount)
        } catch {
            self.showDeposit()
        }
    }

    // MARK: - UI
    fileprivate func setupUI() {
        self.presenter.post.map { $0.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.setupAction()
        self.setupInputBar()
        self.setupCollectionView()
    }
    
    fileprivate func showDeposit() {
        let failVC = FailGiveDonateViewController()
        failVC.depositHandler = {
            let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: WalletViewController.name) as! WalletViewController
            vc.currentIndex.accept(1)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        
        let sheetVC = SheetViewController(controller: failVC, sizes: [.fixed(176)])
        sheetVC.topCornersRadius = 16
        self.present(sheetVC, animated: true)
    }
    
    fileprivate func showGiveMore(profile: Profile, amount: Double) {
        let storyboard = UIStoryboard(name: "Give", bundle: nil)
        let giveMove = storyboard.instantiateViewController(withIdentifier: GiveMoreViewController.className) as! GiveMoreViewController
        giveMove.amountOptions.accept([10, 20, 50])
        giveMove.profile.accept(profile)
        giveMove.amount.accept(amount)
        giveMove.giveHandler =  { count in
            self.giveDonate(profile: profile, amount: count)
        }
        giveMove.modalTransitionStyle = .crossDissolve
        giveMove.modalPresentationStyle = .overCurrentContext
        self.present(giveMove, animated: true)
        
    }
    
    fileprivate func setupAction() {
        self.presenter.post.map { $0.creator.profile.id == Session.shared.user?.id }.map { $0 ? #imageLiteral(resourceName: "editPost") : #imageLiteral(resourceName: "bookmark-icon") }.bind(to: self.actionButton.rx.image(for: .normal))
            .disposed(by: self.disposeBag)
        self.presenter.post.filter { $0.creator.profile.id != Session.shared.user?.id }.map { $0.saving ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-icon") }
            .bind(to: self.actionButton.rx.image(for: .normal))
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupInputBar() {
        self.inputBarView.maxTextViewHeight = 100.0
        self.inputBarView.delegate = self
        self.inputBarView.backgroundColor = .white 
        self.inputBarView.inputTextView.dataDetectorTypes = [.link]
        self.inputBarView.insertBookPrefixHandler = self.insertBookTagPrefix
        
        self.autoCompleteManager = .init(textView: self.inputBarView.inputTextView)
        self.autoCompleteManager.defaultTextAttributes = [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: UIColor.navy]
        
        self.autoCompleteManager.maxSpaceCountDuringCompletion = 1
        self.autoCompleteManager.deleteCompletionByParts = false
        self.decorator = DecoratorAutoComplete(autoCompletes: [
            UserAutoComplete(prefix: CommentPost.USER_TAG_PREFIX, attributedTextAttributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue, .backgroundColor: UIColor.fadedBlue.withAlphaComponent(0.1)], inputBar: self.inputBarView, autoCompleteInput: self.autoCompleteManager),
            BookAutoComplete(prefix: CommentPost.BOOK_TAG_PREFIX, attributedTextAttributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue], inputBar: self.inputBarView, autoCompleteInput: self.autoCompleteManager)
        ])
        self.decorator.autoCompletes.forEach { self.autoCompleteManager.register(prefix: $0.prefix, with: $0.attributedTextAttributes) }
        self.autoCompleteManager.delegate = self.decorator
        self.inputBarView.inputPlugins = [self.autoCompleteManager]
        self.presenter.items.filter { [weak self] (_) -> Bool in
            return self?.commentFirstResponder ?? false
        }
        .elementAt(0)
        .bind { [weak self] (_) in
            self?.inputBarView.inputTextView.becomeFirstResponder()
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.backgroundColor = .white
        self.presenter.post.map { $0.body }.filter { !$0.isEmpty }.distinctUntilChanged()
            .map { PostContentCollectionViewCell.size(content: $0, in: UIScreen.main.bounds.size) }
            .bind(onNext: self.contentPostSize.accept)
            .disposed(by: self.disposeBag)
        self.contentPostSize.distinctUntilChanged().bind { [weak self] (size) in
            self?.collectionView.reloadData()
        }
        .disposed(by: self.disposeBag)
        self.registerCell()
        self.setupDatasource()
        self.setupCollectionLayout()
        self.collectionView.keyboardDismissMode = .interactive
    }
    
    fileprivate func registerCell() {
        self.collectionView.register(UINib.init(nibName: TitlePostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: TitlePostCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: PostContentCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: PostContentCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: BookInPostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookInPostCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: PostTagCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: PostTagCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: CommentPostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: CommentPostCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: OwnerPostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: OwnerPostCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: SummayPostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: SummayPostCollectionViewCell.identifier)
        
        self.collectionView.register(UINib(nibName: CommentHeaderCollectionReusableView.className, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CommentHeaderCollectionReusableView.identifier)
        
        self.collectionView.register(UINib(nibName: ActivityPostFooterCollectionReusableView.className, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ActivityPostFooterCollectionReusableView.identifier)
    }
    
    fileprivate func setupDatasource() {
        self.datasource = .init(configureCell: { [weak self] (datasource, collectionView, indexPath, element) -> UICollectionViewCell in
            if let post = element as? Post {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitlePostCollectionViewCell.identifier, for: indexPath) as! TitlePostCollectionViewCell
                cell.post.accept(post)
                cell.sizeCell.accept(TitlePostCollectionViewCell.size(post: post, in: collectionView.frame.size))
                cell.openProfile = self?.presenter.open(profile:)
                return cell
            } else if let content = element as? String {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostContentCollectionViewCell.identifier, for: indexPath) as! PostContentCollectionViewCell
                cell.downloadImage = self?.presenter.downloadImage(url:)
//                cell.updateCollection = { [weak self] size in
//                    self?.contentPostSize.accept(size)
//                }
                cell.sizeCell.accept(self?.contentPostSize.value ?? .zero)
                cell.content.accept(content)
                
                return cell
            } else if let books = element as? [BookInfo] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BookInPostCollectionViewCell.identifier, for: indexPath) as! BookInPostCollectionViewCell
                cell.sizeCell.accept(BookInPostCollectionViewCell.size(in: collectionView.frame.size))
                cell.books.accept(books)
                cell.openBookDetail = self?.presenter.openBookDetail(book:)
                return cell
            } else if let tags = element as? [PostTagItem] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostTagCollectionViewCell.identifier, for: indexPath) as! PostTagCollectionViewCell
                cell.items.accept(tags)
                cell.openHashtag = self?.presenter.open(hashtag:)
                cell.openCategory = self?.presenter.open(category:)
                return cell
            } else if let profile = element as? PostCreator {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OwnerPostCollectionViewCell.identifier, for: indexPath) as! OwnerPostCollectionViewCell
                cell.sizeCell.accept(OwnerPostCollectionViewCell.size(profile: profile, in: collectionView.frame.size))
                cell.owner.accept(profile)
                cell.followHandler = self?.presenter.follow(creator:)
                cell.openProfile = self?.presenter.open(profile:)
                return cell
            } else if let summary = element as? PostSummary {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SummayPostCollectionViewCell.identifier, for: indexPath) as! SummayPostCollectionViewCell
                cell.summary.accept(summary)
                cell.openListReaction = self?.presenter.openListReactionPost
                return cell
            } else if let comment = element as? WrappedCommentPostAttributes {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentPostCollectionViewCell.identifier, for: indexPath) as! CommentPostCollectionViewCell
                cell.layer.zPosition = CGFloat(indexPath.section + indexPath.row)
                cell.replyHandler =  { [weak self] comment in
                    self?.replyEvent(comment: comment)
                }
                cell.removeHandler = self?.presenter.remove(comment:)
                cell.editHandler = self?.editComment
                cell.reactionCommentHandler = { [weak self] (commentId,reaction,count) in
                    self?.presenter.reactionComment(comment: commentId, reaction: reaction, count: count)
                }
                cell.nextReplyHandler = self?.presenter.nextReplies(comment:)
                cell.openProfile = self?.presenter.open(profile:)
                cell.openBookDetail = self?.presenter.openBookDetail(book:)
                cell.openListUserReaction = self?.presenter.openListReaction(comment:)
                cell.comment.accept(comment)
                return cell
            }
            fatalError()
        }, configureSupplementaryView: { [weak self] (datasource, collectionView, kind, indexPath) -> UICollectionReusableView in
            guard let item = PostDetailItem(rawValue: indexPath.section) else { fatalError() }
            switch item {
            case .detail:
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ActivityPostFooterCollectionReusableView.identifier, for: indexPath) as! ActivityPostFooterCollectionReusableView
                footer.reactionHandler = { [weak self] (reaction, count) in
                    let obser = self?.presenter.reactionPost(id: reaction, count: count)
                        .do(onNext: { _ in
                            let creator = datasource.sectionModels.first(where: { $0.identity == .detail })?.items.first(where: { $0 as? PostCreator != nil }) as! PostCreator
                            if creator.profile.id != Session.shared.user?.id {
                                self?.giveDonate(profile: creator.profile, amount: Double(count))
                            }
                        })
                    return obser ?? .empty()
                }
                
                footer.updateReactionWhenInteracing = { [weak self] (userReaction) in
                    self?.presenter.updateReactionPostWhenInteracting(reaction: userReaction)
                }
                footer.commentHandler = { [weak self] in
                    self?.inputBarView.inputTextView.becomeFirstResponder()
                }
                if let post = datasource.sectionModels[indexPath.section].items.first(where: { $0 as? Post != nil }) as? Post {
                    footer.isReaction.accept(post.isInteracted)
                    footer.userReactCount = post.userReaction.reactCount
                    footer.postReactCount = post.summary.reactCount
                    footer.giveAction = { [weak self] in
                        self?.showGiveMore(profile: post.creator.profile, amount: Double(post.userReaction.reactCount))
                    }
                }
                return footer
            case .comment:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CommentHeaderCollectionReusableView.identifier, for: indexPath) as! CommentHeaderCollectionReusableView
                header.layer.zPosition = 0
                header.selectSortHandler = { [weak self] in
                    self?.presenter.openSortComment { sort in
                        header.sort.accept(sort)
                    }
                }
                return header
            }
        })
        
        self.presenter.items.bind(to: self.collectionView.rx.items(dataSource: self.datasource)).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupCollectionLayout() {
        self.collectionView.delegate = self
        var contentInset = self.collectionView.contentInset
        contentInset.bottom = self.inputBarView.intrinsicContentSize.height
        self.collectionView.contentInset = contentInset
    }
    
    fileprivate func insertReplyCommentInTextView(comment: CommentPost) {
        guard comment.user.id != Session.shared.user?.id else { return }
        
        guard let userAutoComplete = self.decorator.autoCompletes.first(where: { $0.prefix == CommentPost.USER_TAG_PREFIX }), var attrs = userAutoComplete.attributedTextAttributes else { return }
        
        attrs[.autocompleted] = true
        let url = URL(string: AppConfig.sharedConfig.get("web_url") + "users/\(comment.user.id)")!
        attrs[.autocompletedContext] = ["id": comment.user.id, "prefix": CommentPost.USER_TAG_PREFIX, "url": url]
        let attributes = NSMutableAttributedString(string: "\(comment.user.name)", attributes: attrs)
        attrs = self.autoCompleteManager.defaultTextAttributes
        attrs[.autocompleted] = false
        attrs[.autocompletedContext] = nil
        attributes.append(.init(string: " ", attributes: attrs))
        self.inputBarView.inputTextView.attributedText = attributes
    }
    
    fileprivate func insertBookTagPrefix() {
        let attributed = NSMutableAttributedString(attributedString: self.inputBarView.inputTextView.attributedText)
        attributed.append(.init(string: " \(CommentPost.BOOK_TAG_PREFIX)", attributes: [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: UIColor.navy]))
        self.inputBarView.inputTextView.attributedText = attributed
    }
    
    fileprivate func editComment(_ comment: CommentPost, attributed: NSAttributedString) {
        self.inputBarView.inputTextView.becomeFirstResponder()
        self.presenter.edit(comment: comment)
        self.inputBarView.inputTextView.attributedText = attributed
        attributed.enumerateAttribute(.autocompleted, in: .init(location: 0, length: attributed.length), options: .reverse) { (_, subrange, stop) in
            guard let range = Range(subrange, in: attributed.string) else { return }
            let substring = String(attributed.string[range])
            if let context = attributed.attribute(.autocompletedContext, at: subrange.location, effectiveRange: nil) as? [String: Any], let id = context["id"] as? Int, let prefix = context["prefix"] as? String {
                var autoComplete = self.decorator.autoCompletes.first(where: { $0.prefix == prefix })
                autoComplete?.tags.insert(.init(id: id, text: substring))
            }
        }
    }
    
    fileprivate func showConfirm(profile: Profile, amount: Double) {
        let confirmVC = GiveDonationConfirmViewController()
        confirmVC.profile.accept(profile)
        confirmVC.amount.accept(amount)
        confirmVC.showTransaction = { 
            let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
            let walletVC = storyboard.instantiateViewController(withIdentifier: WalletViewController.name)
            self.navigationController?.pushViewController(walletVC, animated: true)
        }
        confirmVC.giveMoreHandler = { _ in
            self.showGiveMore(profile: profile, amount: amount)
        }
        let sheetVC = SheetViewController(controller: confirmVC, sizes: [.fixed(176)])
        sheetVC.topCornersRadius = 16
        self.present(sheetVC, animated: true)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
        self.collectionViewEvent()
        self.cancelReplyEvent()
        self.textViewEvent()
        self.notificationEvent()
        self.keyboardEvent()
        self.actionEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.presenter.backScreen()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func replyEvent(comment: CommentPost) {
        self.inputBarView.inputTextView.becomeFirstResponder()
        self.presenter.reply(comment: comment)
        self.insertReplyCommentInTextView(comment: comment)
        var userAutoComplete = self.decorator.autoCompletes.first(where: { $0.prefix == CommentPost.USER_TAG_PREFIX })
        
        guard comment.user.id != Session.shared.user?.id else { return }
        
        userAutoComplete?.tags.insert(.init(id: comment.user.id, text: comment.user.name))
        self.presenter.commentTags(user: comment.user)
        
    }
    
    fileprivate func resetSession() {
        self.inputBarView.inputTextView.text = ""
        self.decorator.removeAllTags()
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.didScroll.withLatestFrom(Observable.just(self.collectionView).compactMap { $0 })
            .map { (collectionView) -> Bool in
                return collectionView.visibleCells.first(where: { $0.reuseIdentifier == TitlePostCollectionViewCell.identifier }) != nil
            }
        .bind(to: self.titleLabel.rx.isHidden)
        .disposed(by: self.disposeBag)
        
        self.collectionView.rx.willBeginDecelerating.asObservable().compactMap { [weak self] _ in self?.collectionView }
            .filter({ (collectionView) -> Bool in
                return collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.frame.height)
            })
            .filter({ (collectionView) -> Bool in
                let translation = collectionView.panGestureRecognizer.translation(in: collectionView.superview)
                return translation.y < -70.0
            })
        .subscribe(onNext: { [weak self] (_) in
            // call api this here
            self?.presenter.nextComment()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func cancelReplyEvent() {
        self.inputBarView.cancelReplyHandler = { [weak self] in
            self?.presenter.resetComment()
            self?.resetSession()
        }
    }
    
    fileprivate func keyboardEvent() {
        Observable.of(
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification),
            NotificationCenter.default.rx.notification(UIResponder.keyboardDidHideNotification)
        )
        .merge()
        .flatMap { (notification) -> Observable<CGRect> in
            guard let userInfo = notification.userInfo as? [String: AnyObject], let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                    return .empty()
            }
            return .just(keyboardFrame)
        }
        .withLatestFrom(Observable.just(self)) { (rect, vc) -> CGFloat in
            let localKeyboardOrigin = vc.view.convert(rect.origin, from: nil)
            let keyboardInset = max(vc.view.frame.height - localKeyboardOrigin.y, 0)
            return keyboardInset
        }
        .subscribe(onNext: { [weak self] (keyboardHeight) in
//            var contentInset = self?.collectionView.contentInset ?? .zero
//            contentInset.bottom = (self?.inputBarView.intrinsicContentSize.height ?? .zero) + keyboardHeight
            self?.collectionBottomConstraint.constant = keyboardHeight
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func notificationEvent() {
        NotificationCenter.default.rx.notification(UserAutoComplete.ADD_USER_TAG)
            .compactMap { $0.object as? Profile }
            .subscribe(onNext: self.presenter.commentTags(user:))
            .disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(UserAutoComplete.REMOVE_USER_TAG)
            .compactMap { $0.object as? Int }
            .subscribe(onNext: self.presenter.removeTags(userId:))
            .disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(BookAutoComplete.ADD_BOOK_TAG)
            .compactMap { $0.object as? BookInfo }
            .subscribe(onNext: self.presenter.commentTags(book:))
            .disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(BookAutoComplete.REMOVE_BOOK_TAG)
            .compactMap { $0.object as? Int }
            .subscribe(onNext: self.presenter.removeTags(editionId:))
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func textViewEvent( ){
        self.inputBarView.inputTextView.rx.didBeginEditing.subscribe(onNext: { [weak self] (_) in
            self?.presenter.startComment()
        })
            .disposed(by: self.disposeBag)
        
        self.inputBarView.inputTextView.rx.didEndEditing.subscribe(onNext: { [weak self] (_) in
            self?.presenter.resetComment()
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func actionEvent() {
       let shared = self.actionButton.rx.tap.withLatestFrom(self.presenter.post)
            .share()
        shared.filter { $0.creator.profile.id == Session.shared.user?.id }
            .bind { [weak self] (post) in
                let step = StepCreateArticleViewController()

                let storyboard = UIStoryboard(name: "CreateArticle", bundle: nil)
                let createArticle = storyboard.instantiateViewController(withIdentifier: CreatePostViewController.className) as! CreatePostViewController
                createArticle.presenter = SimpleCreatePostPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimpleCreatePostRouter(viewController: createArticle, provider: step))
                step.add(step: .init(controller: createArticle, direction: .forward))
                self?.navigationController?.pushViewController(step, animated: true)
            }
            .disposed(by: self.disposeBag)
        
        shared.filter { $0.creator.profile.id != Session.shared.user?.id }
            .bind { (post) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            }
            .disposed(by: self.disposeBag)
        
        shared.filter { $0.creator.profile.id != Session.shared.user?.id && Session.shared.isAuthenticated }
            .map { !$0.saving }
            .do (onNext: { (value) in
                self.actionButton.setImage(value ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-icon"), for: .normal)
            })
            .bind(onNext: self.presenter.bookmark(value:))
            .disposed(by: self.disposeBag)
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CreatePostViewController.segueIdentifier {
            let vc = segue.destination as? CreatePostViewController
            let step = StepCreateArticleViewController()
            vc?.presenter = SimpleCreatePostPresenter(post: sender as! Post, imageUsecase: DefaultImageUsecase(), router: SimpleCreatePostRouter(viewController: vc, provider: step))
            step.add(step: .init(controller: vc!, direction: .forward))
        } else if segue.identifier == "showBookDetail" {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == "showVistor" {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        }
    }

}

extension PostDetailViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.presenter.item(indexPath: indexPath)
        if let post = item as? Post {
            return TitlePostCollectionViewCell.size(post: post, in: collectionView.frame.size)
        } else if item is String {
            return self.contentPostSize.value
        } else if item is [BookInfo] {
            return BookInPostCollectionViewCell.size(in: collectionView.frame.size)
        } else if item is [PostTagItem] {
            return PostTagCollectionViewCell.size(in: collectionView.frame.size)
        } else if let profile = item as? PostCreator {
            return OwnerPostCollectionViewCell.size(profile: profile, in: UIScreen.main.bounds.size)
        } else if item is PostSummary {
            return SummayPostCollectionViewCell.size(in: collectionView.frame.size)
        } else if let comment = item as? WrappedCommentPostAttributes {
            return CommentPostCollectionViewCell.size(comment: comment, in: collectionView.frame.size)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let s = self.presenter.section(indexPath: .init(row: 0, section: section))
        switch s.model {
        case .detail:
            return ActivityPostFooterCollectionReusableView.size(in: collectionView.frame.size)
        case .comment: return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let s = self.presenter.section(indexPath: .init(row: 0, section: section))
        switch s.model {
        case .detail: return .zero
        case .comment: return CommentHeaderCollectionReusableView.size(in: collectionView.frame.size)
        }
    }
}

extension PostDetailViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        var text = text
        if text.last == "\n" {
            text.removeLast()
        }
        let html = self.convertHtml(from: inputBar.inputTextView.attributedText, text: text)
        self.presenter.sendComment(content: html)
        self.resetSession()
        self.inputBarView.hideReply()
        inputBar.inputTextView.resignFirstResponder()
    }
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
    }
    
    fileprivate func convertHtml(from attributed: NSAttributedString, text: String) -> String {
        
        var attr = attributed.copy() as! NSAttributedString
        attributed.enumerateAttribute(.autocompleted, in: .init(location: 0, length: attributed.length), options: .reverse) { (_, subrange, stop) in
            if let value = attributed.attribute(.autocompleted, at: subrange.location, effectiveRange: nil) as? Bool, let context = attributed.attribute(.autocompletedContext, at: subrange.location, effectiveRange: nil) as? [String: Any], let url = context["url"] as? URL, let range = Range(subrange, in: text), value {
                let title = String(text[range])
                let replace = NSAttributedString(string: title, attributes: [.link: url])
                attr = attr.replacingCharacters(in: subrange, with: replace)
            }
        }
        let editorView = TextView(defaultFont: .systemFont(ofSize: 16.0, weight: .medium), defaultParagraphStyle: ParagraphStyle.default, defaultMissingImage: #imageLiteral(resourceName: "lazyImage"))
        editorView.attributedText = attr
        return editorView.getHTML()
    }
}

extension UICollectionView {
    func scrollToBottom() {
        self.numberOfItems(inSection: self.numberOfSections - 1)
        self.scrollToItem(at: .init(row: self.numberOfItems(inSection: self.numberOfSections - 1) - 1, section: self.numberOfSections - 1), at: .bottom, animated: true)
    }
}

extension PostDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
