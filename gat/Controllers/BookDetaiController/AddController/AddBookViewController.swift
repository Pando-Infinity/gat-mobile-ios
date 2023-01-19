////
////  AddBookViewController.swift
////  gat
////
////  Created by Vũ Kiên on 12/04/2017.
////  Copyright © 2017 GaTBook. All rights reserved.
////
//
//import UIKit
//import Cosmos
//import RxCocoa
//import RxSwift
//import JTMaterialSwitch
//
//protocol AddBookDelegate: class {
//    func update()
//}
//
//class AddBookViewController: UIViewController {
//    @IBOutlet weak var titleView: UIView!
//    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var backButton: UIButton!
//    @IBOutlet weak var bookImageView: UIImageView!
//    @IBOutlet weak var nameBookLabel: UILabel!
//    @IBOutlet weak var authorLabel: UILabel!
//    @IBOutlet weak var rateView: CosmosView!
//    @IBOutlet weak var subButton: UIButton!
//    @IBOutlet weak var addButton: UIButton!
//    @IBOutlet weak var countLabel: UILabel!
//    @IBOutlet weak var countView: UIView!
//    @IBOutlet weak var checkButton: UIButton!
//    @IBOutlet weak var loadingView: UIImageView!
//    @IBOutlet weak var numberBookTitleLabel: UILabel!
//    @IBOutlet weak var allowBorrowLabel: UILabel!
//    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
//    
//    fileprivate var switchs: JTMaterialSwitch?
//    
//    weak var delegate: AddBookDelegate?
//    
//    let book: BehaviorSubject<BookInfo> = .init(value: BookInfo())
//    let readingStatus: BehaviorSubject<ReadingStatus?> = .init(value: nil)
//    fileprivate let numberBook: BehaviorSubject<Int> = .init(value: 0)
//    fileprivate let tempNumberBook: BehaviorSubject<Int> = .init(value: 0)
//    fileprivate let isSharingBook: BehaviorSubject<Bool> = .init(value: true)
//    fileprivate let tempIsSharingBook: BehaviorSubject<Bool> = .init(value: false)
//    fileprivate let sendAddBook: BehaviorSubject<Bool> = .init(value: false)
//    fileprivate let disposeBag = DisposeBag()
//
//    //MARK: - View State
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.setupUI()
//        self.getData()
//        self.sendData()
//        self.event()
//    }
//
//    //MARK: - Data
//    fileprivate func getData() {
//        self.book
//            .filter { _ in Status.reachable.value }
//            .do(onNext: { (_) in
//                UIApplication.shared.isNetworkActivityIndicatorVisible = true
//            })
//            .flatMapLatest {
//                InstanceNetworkService
//                    .shared
//                    .total(book: $0)
//                    .catchError { (error) -> Observable<(Int, Int, Int, Int)> in
//                        HandleError.default.showAlert(with: error)
//                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                        return Observable.empty()
//                    }
//            }
//            .do(onNext: { [weak self] (_, notSharingTotal, _, _) in
//                UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                self?.isSharingBook.onNext(notSharingTotal == 0)
//                self?.tempIsSharingBook.onNext(notSharingTotal == 0)
//            })
//            .map { $0 + $1 + $2 + $3 }
//            .do(onNext: { [weak self] (total) in
//                self?.tempNumberBook.onNext(total)
//            })
//            .subscribe(self.numberBook)
//            .disposed(by: self.disposeBag)
//        
//    }
//    
//    //MARK: SendData
//    fileprivate func sendData() {
////        Observable<(BookInfo, Int, Bool, Bool)>
////            .combineLatest(
////                self.book,
////                self.numberBook,
////                self.tempNumberBook,
////                self.isSharingBook,
////                self.sendAddBook,
////                resultSelector: { ($0, $1, $2 - $3, $4) }
////            )
////            .filter { (_, _, _, _, send) in Status.reachable.value && send }
////            .do(onNext: { [weak self] (_) in
////                self?.waiting(true)
////            })
////            .map { (bookInfo, readingStatus, number, sharingStatus, _) in (bookInfo, readingStatus, number, sharingStatus) }
////            .flatMapLatest { [weak self] (book, readingStatus, number, sharingStatus) -> Observable<ReadingStatus> in
////                return InstanceNetworkService
////                    .shared
////                    .add(book: book, readingStatus: readingStatus, number: number, sharingStatus: sharingStatus)
////                    .catchError({ [weak self] (error) -> Observable<ReadingStatus> in
////                        self?.waiting(false)
////                        self?.sendAddBook.onNext(false)
////                        self?.error()
////                        return Observable.empty()
////                    })
////            }
////            .flatMapLatest { Repository<ReadingStatus, ReadingStatusObject>.shared.save(object: $0) }
////            .subscribe(onNext: { [weak self] (_) in
////                self?.waiting(false)
////                self?.sendAddBook.onNext(false)
////                self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
////                self?.completed()
////            })
////            .disposed(by: self.disposeBag)
//    }
//    
//    //MARK: - UI
//    fileprivate func setupUI() {
//        self.titleLabel.text = Gat.Text.AddBook.ADD_BOOK_TITLE.localized()
//        self.numberBookTitleLabel.text = Gat.Text.AddBook.NUMBER_BOOK_TITLE.localized()
//        self.allowBorrowLabel.text = Gat.Text.AddBook.ALLOW_SHARING_TITLE.localized()
//        self.setupInfo()
//        self.setupButton()
//        self.setupSwitchs()
//        self.loadingUI()
//        self.setupNumberBook()
//        self.setupCheckButton()
//    }
//    
//    fileprivate func setupInfo() {
//        self.book
//            .subscribe(onNext: { [weak self] (bookInfo) in
//                self?.nameBookLabel.text = bookInfo.title
//                self?.authorLabel.text = bookInfo.author
//                self?.setupRateView(rating: bookInfo.rateAvg)
//                self?.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookInfo.imageId))!, placeholderImage: DEFAULT_BOOK_ICON)
//            })
//            .disposed(by: self.disposeBag)
//    }
//    
//    fileprivate func setupNumberBook() {
//        self.numberBook
//            .subscribe(onNext: { [weak self] (total) in
//                self?.countLabel.text = "\(total)"
//            })
//            .disposed(by: self.disposeBag)
//    }
//    
//    fileprivate func loadingUI() {
//        let url = AppConfig.sharedConfig.getUrlFile(LOADING_GIF, withExtension: EXTENSION_GIF)
//        self.loadingView.sd_setImage(with: url)
//        self.loadingView.isHidden = true
//    }
//    
//    fileprivate func setupRateView(rating: Double) {
//        self.view.layoutIfNeeded()
//        self.rateView.settings.starSize = Double(self.rateView.frame.height)
//        self.rateView.rating = rating
//        self.rateView.text = String(format: "%0.1f", rating)
//        self.rateView.isUserInteractionEnabled = false
//    }
//    
//    fileprivate func setupButton() {
//        self.view.layoutIfNeeded()
//        self.addButton.circleCorner()
//        self.subButton.circleCorner()
//        self.countView.cornerRadius(radius: self.countView.frame.height / 2.0)
//        self.subButton.backgroundColor = SUB_OFF_BUTTON_COLOR
//    }
//    
//    fileprivate func setupSwitchs() {
//        self.view.layoutIfNeeded()
//        self.switchs = JTMaterialSwitch(size: JTMaterialSwitchSizeNormal, state: JTMaterialSwitchStateOn)
//        self.switchs?.frame.origin = CGPoint(x: self.countView.frame.origin.x + self.countView.frame.width - switchs!.frame.width, y: self.countView.frame.origin.y + self.countView.frame.height + 24.5)
//        self.switchs?.isOn = true
//        self.switchs?.isHidden = true
//        self.switchs?.thumbOffTintColor = THUMB_OFF_TINTCOLOR
//        self.switchs?.trackOffTintColor = TRACK_OFF_TINTCOLOR
//        self.switchs?.trackOnTintColor = TRACK_ON_TINTCOLOR
//        self.switchs?.thumbOnTintColor = THUMB_ON_TINTCOLOR
//        self.switchs?.isHidden = true
//        self.switchs?.addTarget(self, action: #selector(sharingChanged(_:)), for: .valueChanged)
//        self.view.addSubview(self.switchs!)
//    }
//    
//    fileprivate func setupCheckButton() {
//        self.editingCountChangedEvent()
//            .subscribe(onNext: { [weak self] (isEditing) in
//                if isEditing {
//                    self?.checkButton.setBackgroundImage(CHECK_GREEN_ICON, for: .normal)
//                } else {
//                    self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//                    self?.checkButton.setBackgroundImage(CHECK_GRAY_ICON, for: .normal)
//                }
//            })
//            .disposed(by: self.disposeBag)
//    }
//    
//    fileprivate func waiting(_ waiting: Bool) {
//        self.loadingView.isHidden = !waiting
//    }
//    
//    fileprivate func completed() {
//        self.loadingView.isHidden = true
//        self.checkButton.isHidden = true
//        let successView = activityIndicator(frame: self.loadingView.frame)
//        successView.hideAfterTime = 1.5
//        successView.hidesWhenCompleted = true
//        self.titleView.addSubview(successView)
//        successView.completeLoading(success: true) { [weak self] in
//            self?.checkButton.isHidden = false
//            self?.checkButton.setImage(CHECK_GRAY_ICON, for: .normal)
//            successView.removeFromSuperview()
//            self?.delegate?.update()
//            self?.navigationController?.popViewController(animated: true)
//        }
//    }
//    
//    fileprivate func error() {
//        self.loadingView.isHidden = true
//        self.checkButton.isHidden = true
//        let errorView = activityIndicator(frame: self.loadingView.frame)
//        errorView.hideAfterTime = 1.5
//        errorView.hidesWhenCompleted = true
//        self.titleView.addSubview(errorView)
//        errorView.completeLoading(success: false) { [weak self] in
//            self?.checkButton.isHidden = false
//            errorView.removeFromSuperview()
//        }
//    }
//    
//    fileprivate func showAlertNotification() {
//        let okAction = ActionButton(titleLabel: Gat.Text.AddBook.OK_ALERT_TITLE.localized()) { [weak self] in
//            self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//            self?.navigationController?.popViewController(animated: true)
//        }
//        let noAction = ActionButton(titleLabel: Gat.Text.AddBook.NO_ALERT_TITLE.localized(), action: nil)
//        
//        AlertCustomViewController.showAlert(title: Gat.Text.AddBook.NOTIFICATION_CANCEL_ADDBOOK.localized(), message: Gat.Text.AddBook.CANCEL_ADDBOOK_MESSAGE.localized(), actions: [okAction, noAction], in: self)
//    }
//    
//    //MARK: - Event
//    fileprivate func event() {
//        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
//        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//        self.subCountEvent()
//        self.addCountEvent()
//        self.backEvent()
//        self.checkEvent()
//        self.isSharingBookEvent()
//        self.enableAddEvent()
//        self.enableSubEvent()
//    }
//    
//    fileprivate func backEvent() {
//        self.backButton
//            .rx
//            .controlEvent(.touchUpInside)
//            .withLatestFrom(self.editingCountChangedEvent())
//            .subscribe(onNext: { [weak self] (isEditing) in
//                if isEditing {
//                    self?.showAlertNotification()
//                } else {
//                    self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//                    self?.navigationController?.popViewController(animated: true)
//                }
//            })
//            .disposed(by: self.disposeBag)
//    }
//    
//    fileprivate func checkEvent() {
//        self.checkButton
//            .rx
//            .controlEvent(.touchUpInside)
//            .map { _ in true }
//            .subscribe(self.sendAddBook)
//            .disposed(by: self.disposeBag)
//    }
//    
//    fileprivate func subCountEvent() {
//        self.subButton
//            .rx
//            .controlEvent(.touchUpInside)
//            .withLatestFrom(self.numberBook)
//            .map { [weak self] (total) -> Int in
//                self?.addButton.backgroundColor = SUB_ON_BUTTON_COLOR
//                return total - 1
//            }
//            .subscribe(self.numberBook)
//            .disposed(by: self.disposeBag)
//    }
//    
//    fileprivate func enableSubEvent() {
//        Observable<(Int, Int)>
//            .combineLatest(self.numberBook, self.tempNumberBook, resultSelector: { ($0, $1) })
//            .map { $0 != $1 }
//            .do(onNext: { [weak self] (status) in
//                self?.subButton.backgroundColor = status ? SUB_ON_BUTTON_COLOR : SUB_OFF_BUTTON_COLOR
//                self?.switchs?.isOn = status
//            })
//            .subscribe(self.subButton.rx.isUserInteractionEnabled)
//            .disposed(by: self.disposeBag)
//    }
//    
//    fileprivate func addCountEvent() {
//        self.addButton
//            .rx
//            .controlEvent(.touchUpInside)
//            .withLatestFrom(self.numberBook)
//            .map { [weak self] (total) -> Int in
//                self?.subButton.backgroundColor = SUB_ON_BUTTON_COLOR
//                return total + 1
//            }
//            .subscribe(self.numberBook)
//            .disposed(by: self.disposeBag)
//    }
//    
//    fileprivate func enableAddEvent() {
//        Observable<(Int, Int)>
//            .combineLatest(self.numberBook, self.tempNumberBook, resultSelector: { ($0, $1) })
//            .map { $0 - $1 }
//            .map { $0 != 10 }
//            .do(onNext: { [weak self] (status) in
//                self?.addButton.backgroundColor = status ? SUB_ON_BUTTON_COLOR : SUB_OFF_BUTTON_COLOR
//            })
//            .subscribe(self.addButton.rx.isUserInteractionEnabled)
//            .disposed(by: self.disposeBag)
//    }
//
//    
//    @objc
//    fileprivate func sharingChanged(_ sender: JTMaterialSwitch) {
//        self.isSharingBook.onNext(sender.isOn)
//    }
//    
//    fileprivate func editingCountChangedEvent() -> Observable<Bool> {
//        return Observable<Bool>
//            .combineLatest(
//                self.numberBook,
//                self.tempNumberBook,
//                self.isSharingBook,
//                self.tempIsSharingBook,
//                resultSelector: {$0 != $1 || $2 != $3 }
//            )
//    }
//    
//    fileprivate func isSharingBookEvent() {
//        self.isSharingBook
//            .subscribe(onNext: { [weak self] (status) in
//                self?.switchs?.isOn = status
//            })
//            .disposed(by: self.disposeBag)
//    }
//}
//
//extension AddBookViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
//}
//
