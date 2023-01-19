//
//  BookDetailView.swift
//  gat
//
//  Created by Vũ Kiên on 18/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift
import RxCocoa
import CoreLocation
import RealmSwift

class BookDetailView: UIView {
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var nameBookLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var bookImageCenterY: NSLayoutConstraint!
    @IBOutlet weak var nameTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var borrowButton: UIButton!
    @IBOutlet weak var numberLenderLabel: UILabel!
    @IBOutlet weak var readerImage: UIImageView!
    
    weak var bookDetailController: BookDetailViewController?
    
    let bookInfo = BehaviorSubject<BookInfo>(value: BookInfo())
    fileprivate var CONSTANT_LEADING_BOOK_IMAGE: CGFloat = 0.0
    fileprivate var CONSTANT_TRAILING_NAME_LABEL: CGFloat = 0.0
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.CONSTANT_LEADING_BOOK_IMAGE = self.bookImageLeadingConstraint.constant
        self.CONSTANT_TRAILING_NAME_LABEL = self.nameTrailingConstraint.constant
        self.setupUI()
        self.getData()
        self.event()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.setupAddButton()
        self.setupBorrowButton()
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.getBookSharing()
    }
    
    fileprivate func getLocation() -> Observable<CLLocationCoordinate2D> {
        return LocationManager
            .manager
            .location
            .catchErrorJustReturn(CLLocationCoordinate2D())
    }
    
    fileprivate func getUser() -> Observable<Profile?> {
        return Repository<UserPrivate, UserPrivateObject>
            .shared
            .getAll()
            .map { $0.first?.profile }
    }
    
    /**
     List Book Sharing
     */
    func getBookSharing() {
        Observable<(CLLocationCoordinate2D, BookInfo, Profile?, Bool)>
            .combineLatest(
                self.getLocation(),
                self.bookInfo.elementAt(1),
                self.getUser(),
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1, $2, $3) }
            )
            .filter { (_, bookInfo, _, status) in status && bookInfo.editionId != 0 }
            .map { (location, bookInfo, user, _) in (location != CLLocationCoordinate2D() ? location : nil, bookInfo, user) }
            .flatMap {
                BookNetworkService
                    .shared
                    .totalSharing(book: $1, user: $2, location: $0)
                    .catchErrorJustReturn(0)
            }
            .map { "\($0)" }
            .subscribe(self.numberLenderLabel.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    // Add book
    fileprivate func addBook(bookInfo: BookInfo) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        InstanceNetworkService.shared
            .add(book: bookInfo, number: 1, sharingStatus: true)
            .catchError({ (error) -> Observable<()> in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            })
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.addBookSucceeded()
            })
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func save(book: BookInfo) {
        Repository<BookInfo, BookInfoObject>.shared.save(object: book).subscribe().disposed(by: self.disposeBag)
    }

    //MARK: - UI
    fileprivate func addBookSucceeded() {
        let ok = ActionButton(titleLabel: Gat.Text.BookDetail.OK_ALERT_TITLE.localized()) { [weak self] in
            self?.bookDetailController?.getData()
        }
        AlertCustomViewController.showAlert(title: Gat.Text.BookDetail.SUCCEEDED.localized(), message: Gat.Text.BookDetail.ADD_BOOK_SUCCEEDED_MESSAGE.localized(), actions: [ok], in: self.bookDetailController!)
    }
    
    func setupUI() {
        self.bookInfo
            .asObservable()
            .subscribe(onNext: { [weak self] (bookInfo) in
                self?.setupBook(info: bookInfo)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupBook(info: BookInfo) {
        self.layoutIfNeeded()
        self.setupImage(imageId: info.imageId)
        self.nameBookLabel.text = info.title
        self.authorLabel.text = info.author
        self.setupRateView(info.rateAvg)
        self.readButton.setImage(info.saving ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-icon"), for: .normal)
    }
    
    fileprivate func setupRateView(_ rate: Double) {
        self.rateView.settings.starSize = Double(self.rateView.frame.height)
        self.rateView.rating = rate
        self.rateView.text = String(format: "%0.1f", rate)
        self.rateView.isUserInteractionEnabled = false
    }
    
    fileprivate func setupImage(imageId: String) {
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: imageId))!, placeholderImage: DEFAULT_BOOK_ICON)
        self.bookImageView.layer.shadowColor = SHADOW_BOOK_COLOR.cgColor
        self.bookImageView.layer.shadowOffset = CGSize(width: 10, height: 10.0)
        self.bookImageView.layer.shadowOpacity = 0.6
    }
    
    fileprivate func setupAddButton() {
        //self.layoutIfNeeded()
        self.addButton.setTitle(Gat.Text.BookDetail.ADD_BOOK_TITLE.localized(), for: .normal)
        self.addButton.cornerRadius(radius: self.addButton.frame.height / 2.0)
        self.addButton.layer.shadowColor = SHADOW_BUTTON_COLOR.cgColor
        self.addButton.layer.shadowRadius = 40.0
        self.addButton.layer.shadowOffset = CGSize(width: 40.0, height: 40.0)
        self.addButton.layer.shadowOpacity = 0.6
        self.addButton.isUserInteractionEnabled = self.addButton.alpha == 1.0 ? true : false
    }
    
    fileprivate func setupBorrowButton() {
        //self.layoutIfNeeded()
        self.borrowButton.setTitle(Gat.Text.BookDetail.BORROW_BOOK_TITLE.localized(), for: .normal)
        self.borrowButton.cornerRadius(radius: self.borrowButton.frame.height / 2.0)
        self.borrowButton.layer.shadowColor = SHADOW_BUTTON_COLOR.cgColor
        self.borrowButton.layer.shadowRadius = 40.0
        self.borrowButton.layer.shadowOffset = CGSize(width: 40.0, height: 40.0)
        self.borrowButton.layer.shadowOpacity = 0.6
        self.borrowButton.isUserInteractionEnabled = self.borrowButton.alpha == 1.0 ? true : false
    }
    
    func changeFrame(progress: CGFloat) {
        self.nameBookLabel.numberOfLines = progress == 0.0 ? 2 : 1
        self.addButton.alpha = progress == 0.0 ? 1.0 : 0.0
        self.readButton.alpha = progress == 0.0 ? 1.0 : 0.0
        self.rateView.alpha = progress == 0.0 ? 1.0 : 0.0
        self.borrowButton.alpha = progress == 0.0 ? 1.0 : 0.0
        self.numberLenderLabel.alpha = progress == 0.0 ? 1.0 : 0.0
        self.readerImage.alpha = progress == 0.0 ? 1.0 : 0.0
        self.authorLabel.alpha = progress == 0.0 ? 1.0 : 0.0
        self.layoutIfNeeded()
        self.bookImageLeadingConstraint.constant = (self.bookDetailController!.backButton.frame.origin.x + self.bookDetailController!.backButton.frame.width + 2.0) * progress + (1.0 - progress) * self.CONSTANT_LEADING_BOOK_IMAGE
        self.nameTrailingConstraint.constant = (self.bookDetailController!.view.frame.width - self.bookDetailController!.shareButton.frame.origin.x + 2.0) * progress + (1.0 - progress) * self.CONSTANT_TRAILING_NAME_LABEL

        self.nameTopConstraint.constant = progress * (self.bookImageView.frame.height - self.nameBookLabel.frame.height) / 2.0
        self.bookImageHeightConstraint.constant = -(UIApplication.shared.statusBarFrame.height - 5.0) * progress
        self.bookImageCenterY.constant = UIApplication.shared.statusBarFrame.height * progress / 2.0
    }
    
    //MARK: - Event
    func event() {
        self.addEvent()
        self.readButtonEvent()
        self.borrowBookEvent()
    }
    
    fileprivate func addEvent() {
        self.addButton.rx.tap
            .do(onNext: { (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { Session.shared.isAuthenticated }
            .withLatestFrom(self.bookInfo.asObservable())
            .subscribe(onNext: { [weak self] (bookInfo) in
                if bookInfo.instanceCount == 0 {
                    self?.showAlertAddBook(bookInfo)
                    BookNetworkService.shared.info(editionId: bookInfo.editionId).bind(to: self!.bookInfo).disposed(by: self!.disposeBag)
                } else {
                    self?.showAlertAddWhenHaveBefore(bookInfo)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func readButtonEvent() {
        self.readButton
            .rx.tap
            .flatMap({ [weak self] (_) -> Observable<BookInfo> in
                guard let book = try? self?.bookInfo.value() else { return Observable.empty()}
                return Observable<BookInfo>.from(optional: book)
            })
            .do(onNext: { [weak self] (book) in
                self?.readButton.setImage(book.saving ? #imageLiteral(resourceName: "bookmark-icon") : #imageLiteral(resourceName: "bookmark-fill-icon"), for: .normal)
            })
            .flatMap { [weak self] (book) -> Observable<()> in
                return BookNetworkService
                    .shared
                    .saving(bookInfo: book, value: !book.saving)
                    .catchError({ [weak self] (error) -> Observable<()> in
                        self?.readButton.setImage(book.saving ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-icon"), for: .normal)
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { [weak self] (_) in
                guard let value = try? self?.bookInfo.value(), let book = value else { return }
                book.saving = !book.saving
                if !book.saving {
                    self?.bookDetailController?.delegate?.removeBookmark(book: book)
                }
                self?.save(book: book)
                self?.bookInfo.onNext(book)
            })
            .disposed(by: self.disposeBag)
            
    }
    
    fileprivate func borrowBookEvent() {
        self.borrowButton
            .rx.controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.bookDetailController?.performSegue(withIdentifier: Gat.Segue.SHOW_LIST_IDENTIFIER, sender: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    fileprivate func showAlertAddBook(_ book: BookInfo) {
        let ok = ActionButton(titleLabel: Gat.Text.BookDetail.OK_ALERT_TITLE.localized()) { [weak self] in
            guard let value = try? self?.bookInfo.value(), let book = value else { return }
            self?.addBook(bookInfo: book)
            BookNetworkService.shared.info(editionId: book.editionId).bind(to: self!.bookInfo).disposed(by: self!.disposeBag)
            print("IC:\(book.instanceCount)")
        }
        let cancel = ActionButton(titleLabel: Gat.Text.BookDetail.CANCEL_ALERT_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: Gat.Text.BookDetail.ADD_BOOK_TITLE.localized(), message: Gat.Text.BookDetail.ADD_BOOKSHELF_MESSAGE.localized(), actions: [ok, cancel], in: self.bookDetailController!)
    }
    
    fileprivate func showAlertAddWhenHaveBefore(_ book: BookInfo){
        let ok = ActionButton(titleLabel: "YES_CONFIRM".localized()) { [weak self] in
            guard let value = try? self?.bookInfo.value(), let book = value else { return }
            self?.addBook(bookInfo: book)
            print("IC:\(book.instanceCount)")
        }
        let string = String(format: "ALERT_HAVE_BOOK".localized(),book.title)
        let attributedString = NSMutableAttributedString(string: string, attributes: [
          .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
          .foregroundColor: UIColor.black,
          .kern: 0.3
        ])

        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14.0, weight: .bold), range: (string as NSString).range(of: book.title))
        let cancel = ActionButton(titleLabel: "NO_CONFIRM".localized(), action: nil)
        AlertCustomViewController.showAlert2(title: String(format: "TITLE_ALERT_HAVE_BOOK".localized(),book.instanceCount), message: attributedString, actions: [cancel, ok], in: self.bookDetailController!)
    }
}
