//
//  BookDetailTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 06/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift

protocol BookDetailCellDelegate: class {
    func update(bookSharing: BookSharing)
    
    func show(viewController: UIViewController)
}

class BookDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var nameBookLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var sharingCountLabel: UILabel!
    @IBOutlet weak var reviewCountLabel: UILabel!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var borrowButton: UIButton!
    
    weak var delegate: BookDetailCellDelegate?
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let sendBookmark = BehaviorSubject<Bool>(value: false)
    let bookSharing = BehaviorSubject<BookSharing>(value: BookSharing())
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.sendBookmarkToServer()
        self.setupUI()
        self.event()
        self.bookSharing
            .subscribe(onNext: { [weak self] (bookSharing) in
            self?.setup(bookSharing: bookSharing)
        })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Data
    fileprivate func sendBookmarkToServer() {
        Observable.combineLatest(self.bookSharing, self.sendBookmark)
            .filter { $0.1 }
            .map { $0.0 }
            .do(onNext: {  (_) in
                guard Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { _ in Session.shared.isAuthenticated && Status.reachable.value }
            .do(onNext: { [weak self] (bookSharing) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.setupBookmark(savingFlag: bookSharing.info!.saving)
            })
            .flatMapLatest { [weak self] (bookSharing) -> Observable<()> in
                return BookNetworkService
                    .shared
                    .saving(bookInfo: bookSharing.info!, value: bookSharing.info!.saving)
                    .catchError({ (error) -> Observable<()> in
                        self?.sendBookmark.onNext(false)
                        if let error = error as? ServiceError {
                            let message = error.userInfo?["message"] ?? ""
                            CRNotifications.showNotification(type: .error, title: Gat.Text.CommonError.ERROR_ALERT_TITLE.localized(), message: message, dismissDelay: 1.0)
                        }
                        if self?.bookmarkButton.imageView?.image == #imageLiteral(resourceName: "bookmark-fill-icon") {
                            self?.bookmarkButton.setImage(#imageLiteral(resourceName: "bookmark-blue-icon"), for: .normal)
                        } else {
                            self?.bookmarkButton.setImage(#imageLiteral(resourceName: "bookmark-fill-icon"), for: .normal)
                        }
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.sendBookmark.onNext(false)
                guard let value = try? self?.bookSharing.value(), let bookSharing = value else {
                    return
                }
                CRNotifications.showNotification(type: .success, title: Gat.Text.Home.SUCCESS_TITLE.localized(), message: bookSharing.info!.saving ? Gat.Text.Home.ADD_BOOKMARK_MESSAGE.localized() : Gat.Text.Home.REMOVE_BOOKMARK_MESSAGE.localized(), dismissDelay: 1.0)
                self?.delegate?.update(bookSharing: bookSharing)
            })
            .disposed(by: self.disposeBag)
    }
    
    func getInfo(bookSharing: BookSharing) {
        self.bookSharing.onNext(bookSharing)
    }

    fileprivate func addBook(bookInfo: BookInfo) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        InstanceNetworkService.shared
            .add(book: bookInfo, number: 1, sharingStatus: true)
            .catchError({ (error) -> Observable<()> in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            })
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                (self?.delegate as? ExploreBookViewController)?.addBookSucceeded()
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    
    fileprivate func setupUI() {
        self.bookImageView.dropShadow(offset: .zero, radius: 5.0, opacity: 0.5, color: #colorLiteral(red: 0.6358308792, green: 0.635846138, blue: 0.6358379126, alpha: 1))
    }
    
    fileprivate func setup(bookSharing: BookSharing) {
        self.setupInfo(bookSharing.info!)
        self.sharingCountLabel.text = "\(bookSharing.sharingCount)"
        self.reviewCountLabel.text = "\(bookSharing.reviewCount)"
        self.setupBookmark(savingFlag: bookSharing.info!.saving)
        self.setupAddButton()
        self.setupBorrowButton()
    }
    
    fileprivate func setupBookmark(savingFlag: Bool) {
        self.bookmarkButton.setImage(savingFlag ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-blue-icon"), for: .normal)
    }
    
    fileprivate func setupInfo(_ info: BookInfo) {
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: info.imageId)), placeholderImage: DEFAULT_BOOK_ICON)
        self.nameBookLabel.text = info.title
        self.authorLabel.text = info.author
        self.setupRatingView(rating: info.rateAvg)
    }

    fileprivate func setupRatingView(rating: Double) {
        self.layoutIfNeeded()
        self.ratingView.rating = rating
        self.ratingView.settings.starSize = Double(self.ratingView.frame.height)
    }
    
    fileprivate func setupAddButton() {
        self.addButton.cornerRadius(radius: 7.5)
        self.addButton.dropShadow(offset: .zero, radius: 3.0, opacity: 0.5, color: #colorLiteral(red: 0.6358308792, green: 0.635846138, blue: 0.6358379126, alpha: 1))
        self.addButton.setTitle(Gat.Text.TopBorrowBook.ADD_BOOK_TITLE.localized(), for: .normal)
    }
    
    fileprivate func setupBorrowButton() {
        self.borrowButton.cornerRadius(radius: 7.5)
        self.borrowButton.dropShadow(offset: .zero, radius: 3.0, opacity: 0.5, color: #colorLiteral(red: 0.6358308792, green: 0.635846138, blue: 0.6358379126, alpha: 1))
        self.borrowButton.setTitle(Gat.Text.TopBorrowBook.BORROW_TITLE.localized(), for: .normal)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.bookmarkBookEvent()
        self.addBookEvent()
        self.showListSharingEvent()
    }
    
    fileprivate func bookmarkBookEvent() {
        self.bookmarkButton
            .rx
            .controlEvent(.touchUpInside)
            .map { _ in true }.subscribe(self.sendBookmark)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func addBookEvent() {
        self.addButton.rx.tap
            .do(onNext: { (_) in
                if !Session.shared.isAuthenticated {
                    HandleError.default.loginAlert()
                }
            })
            .filter { Session.shared.isAuthenticated }
            .withLatestFrom(self.bookSharing)
            .flatMapLatest { (bookSharing) -> Observable<BookInfo> in
                return Observable<BookInfo>.just(bookSharing.info!)
            }
            .subscribe(onNext: { [weak self] (book) in
                self?.showAddBook(book)
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func showListSharingEvent() {
        self.borrowButton
            .rx
            .controlEvent(.touchUpInside)
            .withLatestFrom(self.bookSharing)
            .map { $0.info! }
            .subscribe(onNext: { [weak self] (bookInfo) in
                let storyboard = UIStoryboard(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "ListBorrowViewController") as! ListBorrowViewController
                vc.bookInfo.onNext(bookInfo)
                self?.delegate?.show(viewController: vc)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    fileprivate func showAddBook(_ book: BookInfo) {
        guard let vc =  UIApplication.shared.topMostViewController() else { return }
        let ok = ActionButton(titleLabel: Gat.Text.BookDetail.OK_ALERT_TITLE.localized()) { [weak self] in
            self?.addBook(bookInfo: book)
        }
        let cancel = ActionButton(titleLabel: Gat.Text.BookDetail.CANCEL_ALERT_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: Gat.Text.BookDetail.ADD_BOOK_TITLE.localized(), message: Gat.Text.BookDetail.ADD_BOOKSHELF_MESSAGE.localized(), actions: [ok, cancel], in: vc)
    }
}

extension BookDetailCellDelegate where Self: ExploreBookViewController {
    func addBookSucceeded() {
        let ok = ActionButton(titleLabel: Gat.Text.BookDetail.OK_ALERT_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: Gat.Text.BookDetail.SUCCEEDED.localized(), message: Gat.Text.BookDetail.ADD_BOOK_SUCCEEDED_MESSAGE.localized(), actions: [ok], in: self)
    }
}
