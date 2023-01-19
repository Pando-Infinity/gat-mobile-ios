//
//  RequestDetailBorrowerViewController.swift
//  gat
//
//  Created by Vũ Kiên on 22/08/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxCocoa
import RxSwift

class RequestDetailBorrowerViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var sendRequestLabel: UILabel!
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var bookNameLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var numberReviewLabel: UILabel!
    @IBOutlet weak var sendMessageLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var intendReturnBookLabel: UILabel!
    @IBOutlet weak var timeReturnButton: UIButton!
    @IBOutlet weak var sendRequestButton: UIButton!
    @IBOutlet weak var messageWaitBorrowLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    let userSharingBook: BehaviorSubject<UserSharingBook> = .init(value: UserSharingBook())
    fileprivate let chooseTime: BehaviorSubject<Int> = .init(value: 1)
    fileprivate let send: BehaviorSubject<Bool> = .init(value: false)
    fileprivate let message: BehaviorSubject<Message> = .init(value: Message())
    fileprivate let disposeBag = DisposeBag()


    // MARK: - LifeTime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getBookInfo()
        self.sendRequest()
        self.createGroup()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Get BookInfo
    fileprivate func getBookInfo() {
        guard let book = try? self.userSharingBook.value(), book.bookInfo.title.isEmpty else { return }
        BookNetworkService.shared.info(editionId: book.bookInfo.editionId).catchErrorJustReturn(book.bookInfo).subscribe(onNext: { [weak self] (b) in
            book.bookInfo = b
            self?.userSharingBook.onNext(book)
        }).disposed(by: self.disposeBag)
    }   

    //MARK: - Send Data
    fileprivate func sendRequest() {
        Observable<(UserSharingBook, Int, Bool)>
            .combineLatest(self.userSharingBook, self.chooseTime, self.send, resultSelector: { ($0, $1, $2) })
            .filter { (_, _, send) in send }
            .map { (userSharingBook, chooseTime, _) in (userSharingBook, ExpectedTime(rawValue: chooseTime)) }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.loading(true)
            })
            .flatMapLatest { [weak self] (userSharingBook, expectation) in
                Observable<UserSharingBook>
                    .combineLatest(
                        Observable<UserSharingBook>.just(userSharingBook),
                        RequestNetworkService
                            .shared
                            .request(to: userSharingBook.profile, borrow: userSharingBook.bookInfo, in: expectation)
                            .catchError { [weak self] (error) -> Observable<BookRequest> in
                                self?.send.onNext(false)
                                self?.loading(false)
                                HandleError.default.showAlert(with: error)
                                return Observable.empty()
                            },
                        resultSelector: { (userSharingBook, bookRequest) -> UserSharingBook in
                            userSharingBook.request = bookRequest
                            return userSharingBook
                        }
                    )
            }
            .do(onNext: { [weak self] (_) in
                self?.loading(false)
            })
            .map { $0.request! }
            .flatMapLatest { Repository<BookRequest, BookRequestObject>.shared.save(object: $0) }
            .subscribe(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }

    fileprivate func createGroup() {
        self.send.filter { $0 }
            .withLatestFrom(self.userSharingBook)
            .flatMap { (userSharingBook) -> Observable<GroupMessage> in
                let user = Repository<UserPrivate, UserPrivateObject>.shared.get()!.profile!
                let groupId = user.id < userSharingBook.profile.id ? "\(user.id):\(userSharingBook.profile.id)" : "\(userSharingBook.profile.id):\(user.id)"
                if let group = Repository<GroupMessage, GroupMessageObject>.shared.get(predicateFormat: "groupId = %@", args: [groupId]) {
                    return Observable.just(group)
                } else {
                    let group = GroupMessage()
                    group.groupId = groupId
                    group.users.append(userSharingBook.profile)
                    return .just(group)
                }
        }
        .flatMap { [weak self] (group) -> Observable<(GroupMessage, Message)> in
            guard let value = try? self?.message.value(), let message = value else { return Observable.empty() }
            return Observable.just((group, message))
        }
        .flatMap { MessageService.shared.send(message: $1, in: $0).catchErrorJustReturn(()) }
        .subscribe().disposed(by: self.disposeBag)
    }

    //MARK: - UI
    fileprivate func setupUI() {
        self.userSharingBook
            .subscribe(onNext: { [weak self] (userSharingBook) in
                self?.setupSendRequestLabel(profile: userSharingBook.profile)
                self?.setupBookInfo(userSharingBook.bookInfo)
                self?.setup(sharingCount: userSharingBook.sharingCount, reviewCount: userSharingBook.reviewCount)
                self?.setupMessageTextView(userSharingBook: userSharingBook)
                if userSharingBook.availableStatus {
                    self?.titleLabel.text = Gat.Text.RequestDetailBorrower.BORROW_TITLE.localized()
                    self?.sendRequestButton.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    self?.messageWaitBorrowLabel.isHidden = true
                } else {
                    self?.titleLabel.text = Gat.Text.RequestDetailBorrower.ON_HOLD_TITLE.localized()
                    self?.sendRequestButton.backgroundColor = #colorLiteral(red: 0.4862745098, green: 0.7725490196, blue: 0.462745098, alpha: 1)
                    self?.messageWaitBorrowLabel.text = Gat.Text.RequestDetailBorrower.ON_HOLD_MESSAGE.localized()
                    self?.messageWaitBorrowLabel.sizeToFit()
                }
            })
            .disposed(by: self.disposeBag)
        self.sendMessageLabel.text = Gat.Text.RequestDetailBorrower.SEND_MESSAGE.localized()
        self.intendReturnBookLabel.text = Gat.Text.RequestDetailBorrower.INTEND_RETURN_MESSAGE.localized()
        self.setupSendButton()
        self.setupTimeReturnButton()
    }

    fileprivate func setupSendRequestLabel(profile: Profile) {
        self.sendRequestLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width * 0.9
        let attributedString = NSMutableAttributedString(string: String(format: Gat.Text.RequestDetailBorrower.SEND_REQUEST_TO_TITLE.localized(), profile.name))
        let range = (attributedString.string as NSString).range(of: profile.name)
        attributedString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)], range: range)
        self.sendRequestLabel.attributedText = attributedString
        self.sendMessageLabel.sizeToFit()
    }

    fileprivate func setupBookInfo(_ bookInfo: BookInfo) {
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookInfo.imageId))!, placeholderImage: DEFAULT_BOOK_ICON)
        self.bookImageView.isUserInteractionEnabled = true
        self.bookNameLabel.text = bookInfo.title
        self.authorLabel.text = bookInfo.author
        self.setupRateView(rating: bookInfo.rateAvg)
    }
    
    fileprivate func setup(sharingCount: Int, reviewCount: Int) {
        let attributtedString = NSMutableAttributedString(string: "\(sharingCount) " + Gat.Text.RequestDetailBorrower.REVIEW_BOOK_TITLE.localized())
        let range = ("\(reviewCount)" as NSString).range(of: attributtedString.string)
        attributtedString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11.0), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.1254901961, alpha: 1)], range: range)
        self.numberReviewLabel.attributedText = attributtedString

    }

    fileprivate func setupRateView(rating: Double) {
        self.view.layoutIfNeeded()
        self.rateView.rating = rating
        self.rateView.settings.starSize = Double(self.rateView.frame.height)
        self.rateView.text = String(format: "%.2f", rating)
        self.rateView.isUserInteractionEnabled = false
    }

    fileprivate func setupMessageTextView(userSharingBook: UserSharingBook) {
        guard userSharingBook.request == nil else {
            return
        }
        if userSharingBook.availableStatus {
            self.messageTextView.text = String(format: Gat.Text.RequestDetailBorrower.BORROW_FORMAT_MESSAGE.localized(), userSharingBook.profile.name, userSharingBook.bookInfo.title)
        } else {
            self.messageTextView.text = String(format: Gat.Text.RequestDetailBorrower.ONHOLD_FORMAT_MESSAGE.localized(), userSharingBook.profile.name, userSharingBook.bookInfo.title)
        }

    }

    fileprivate func setupSendButton() {
        self.sendRequestButton.setTitle(Gat.Text.RequestDetailBorrower.SEND_REQUEST_TITLE.localized(), for: .normal)
        self.view.layoutIfNeeded()
        self.sendRequestButton.cornerRadius(radius: self.sendRequestButton.frame.height / 2.0)
    }

    fileprivate func setupTimeReturnButton() {
        self.view.layoutIfNeeded()
        self.timeReturnButton.cornerRadius(radius: self.timeReturnButton.frame.height / 2.0)
        self.chooseTime
            .map { ExpectedTime(rawValue: $0) }
            .filter { $0 != nil }
            .map { $0!.toString }
            .subscribe(onNext: { [weak self] (text) in
                self?.timeReturnButton.setTitle(text, for: .normal)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func loading(_ isLoading: Bool) {
        self.view.isUserInteractionEnabled = !isLoading
        UIApplication.shared.isNetworkActivityIndicatorVisible = isLoading
    }

    //MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.sendRequestEvent()
        self.showBookDetail()
        self.messageTextViewEvent()
        self.timeReturnButtonEvent()
        self.view
            .rx
            .tapGesture()
            .when(.recognized).bind { [weak self] (gesture) in
                self?.messageTextView.resignFirstResponder()
            }
            .disposed(by: self.disposeBag)
    }

    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: self.disposeBag)
    }

    fileprivate func timeReturnButtonEvent() {
        self.timeReturnButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.chooseTime)
            .flatMapLatest { (chooseTime) -> Observable<Int> in
                return Observable<Int>.create({ (observer) -> Disposable in
                    SLPickerView.showTextPickerView(withValues: NSMutableArray(array: ExpectedTime.all.map { $0.toString }), withSelected: ExpectedTime.all[chooseTime].toString, completionBlock: { (selected) in
                        let choose = ExpectedTime.all.map { $0.toString }.index(of: selected ?? "") ?? 1
                        observer.onNext(choose)
                    })
                    return Disposables.create()
                })
            }
            .subscribe(self.chooseTime)
            .disposed(by: self.disposeBag)
    }

    fileprivate func sendRequestEvent() {
        self.sendRequestButton
            .rx
            .tap
            .asObservable()
            .map { _ in true }
            .subscribe(self.send)
            .disposed(by: self.disposeBag)
    }

    fileprivate func showBookDetail() {
        self.bookImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .withLatestFrom(self.userSharingBook)
            .map { $0.bookInfo }
            .subscribe(onNext: { [weak self] (book) in
                self?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: book as Any)
            })
            .disposed(by: self.disposeBag)
    }

    fileprivate func messageTextViewEvent() {
        self.messageTextView.delegate = self
        self.messageTextView
            .rx
            .text
            .orEmpty
            .asObservable()
            .do(onNext: { [weak self] (text) in
                if text.isEmpty {
                    guard let value = try? self?.userSharingBook.value(), let userSharingBook = value else {
                        return
                    }
                    self?.setupMessageTextView(userSharingBook: userSharingBook)
                }
            })
            .flatMapLatest { (text) -> Observable<Message> in
                return Repository<UserPrivate, UserPrivateObject>.shared.getFirst().map({ (userPrivate) -> Message in
                    let date = Date()
                    let message = Message()
                    message.messageId = "\(Int64(date.timeIntervalSince1970 * 1000.0))_\(userPrivate.id)"
                    message.content = text
                    message.user = userPrivate.profile
                    message.sendDate = date
                    message.readTime["\(userPrivate.id)"] = date
                    return message
                })
            }
            .subscribe(onNext: self.message.onNext)
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        }
    }
}

extension RequestDetailBorrowerViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
