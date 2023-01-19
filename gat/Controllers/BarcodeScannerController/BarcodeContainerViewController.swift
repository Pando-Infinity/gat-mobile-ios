//
//  BarcodeContainerViewController.swift
//  gat
//
//  Created by Vũ Kiên on 26/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import AVFoundation
import MTBBarcodeScanner
import FirebaseAnalytics

class BarcodeContainerViewController: UIViewController {
    
    @IBOutlet var previewView: UIView!
    @IBOutlet weak var toggleTorchLabel: UILabel!
    @IBOutlet weak var scanArea: UIView!
    @IBOutlet weak var notificationMessageTextView: UITextView!
    
    weak var delegate: BarcodeScannerDelegate?
    
    //MARK: - Private Data Properties
    fileprivate var scanner: MTBBarcodeScanner?
    fileprivate let disposeBag = DisposeBag()
    fileprivate let isbnBook: BehaviorSubject<String> = .init(value: "")
    fileprivate var torchStatus: Variable<Bool> = Variable(false)
    
    
    var type: ScanBarcodeType = .all
    var joinHandler: ((Int) -> Bool)?
    var showJoin: ((Int) -> Void)?
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getBookInfo()
        self.setupEvent()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startBarcodeScanner()
    }
    
    /**Bật quét mã code liên tục ở đây, chỉ bật được chương trình quét mã sau khi toàn bộ giao
     diện được tải
     Sau khi lấy được Book về thì chuyển sang segue: showBookDetail*/
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startBarcodeScanner()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.scanner?.stopScanning()
        self.torchStatus.value = false
    }
    
    // MARK: - Data
    fileprivate func getBookInfo() {
        self.isbnBook
            .filter { !$0.isEmpty }
            .filter { _ in Status.reachable.value }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap { [weak self] (isbn) -> Observable<Int> in
                return BookNetworkService.shared.info(isbn: isbn)
                    .catchError { (error) -> Observable<Int> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error) { [weak self] in
                            self?.startBarcodeScanner()
                        }
                        return .empty()
                }
        }
        .map { (editionId) -> BookInfo in
            let book = BookInfo()
            book.editionId = editionId
            return book
        }
        .subscribe(onNext: { [weak self] (book) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: book)
        })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    private func setupUI() {
        self.notificationMessageTextView.text = Gat.Text.Barcode.BARCODE_MESSAGE.localized()
        self.setupDisplayTorchStatus()
        self.scanner?.didStartScanningBlock = { [weak self] in
            if let frame = self?.scanArea.frame {
                self?.scanner?.scanRect = frame
            }
        }
    }
    
    private func setupDisplayTorchStatus() {
        self.torchStatus
            .asObservable()
            .map { $0 ? Gat.Text.Barcode.TURN_ON_TITLE.localized() : Gat.Text.Barcode.TURN_OFF_TITLE.localized() }
            .bind(to: toggleTorchLabel.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showAlertPermission() {
        let settingAction = ActionButton.init(titleLabel: Gat.Text.CommonError.SETTING_ALERT_TITLE.localized()) {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: { (status) in
                
            })
        }
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.ERROR_CAMERA_TITLE.localized(), message: Gat.Text.CommonError.CAMERA_ALERT_MESSAGE.localized(), actions: [settingAction], in: self)
    }
    
    private func setupBarcodeScanner() {
        self.scanner = .init(previewView: self.previewView)
    }
    
    fileprivate func showErorrAlert() {
        let ok = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized()) { [weak self] in
            self?.startBarcodeScanner()
        }
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.ERROR_ALERT_TITLE.localized(), message: Gat.Text.Barcode.CAN_NOT_SCAN_CODE_MESSAGE.localized(), actions: [ok], in: self)
    }
    
    
    // MARK: - Event
    private func setupEvent() {
        self.setupTorchStatusChangedEvent()
        self.setupBarcodeScanner()
    }
    
    @IBAction func toggleTorch(_ sender: UIButton) {
        self.torchStatus.value = !self.torchStatus.value
    }
    
    private func setupTorchStatusChangedEvent() {
        self.torchStatus
            .asObservable()
            .subscribe(onNext: {[weak self] status in
                if let hasTorch = self?.scanner?.hasTorch(), hasTorch == true {
                    self?.scanner?.torchMode = status ? .on : .off
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    private func startBarcodeScanner() {
        // Kiểm tra người dùng đã cấp quyền sử dụng Camera.
        MTBBarcodeScanner.requestCameraPermission(success: { [weak self] success in
            if success {
                self?.startScan()
            } else {
                self?.showAlertPermission()
            }
        })
    }
    func verifyUrl (urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url = NSURL(string: urlString) {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
    
    private func startScan() {
        do {
            try self.scanner?.startScanning(resultBlock: { [weak self] codes in
                DispatchQueue.main.async { [weak self] in
                    let value = codes?.filter { $0.stringValue != nil }.filter { !($0.stringValue?.isEmpty ?? true) }.map { $0.stringValue! }.first
                    guard let result = value, let type = self?.type else { return }
                    print("RESULTS: \(result)")
                    self?.torchStatus.value = false
                    switch type {
                    case .book, .all:
                        if self!.verifyUrl(urlString: result){
                            let url = URL(string: result)
                            if url!.host != "gatbook.org" || url!.scheme != "https" {
                                self?.scanner?.stopScanning()
                                let ok = ActionButton(titleLabel: Gat.Text.BookDetail.OK_ALERT_TITLE.localized()) { [weak self] in
                                    self?.navigationController?.popViewController(animated: true)
                                }
                                AlertCustomViewController.showAlert(title: "Host error", message: "Url is not suitable", actions: [ok], in: self!)
                            } else {
                                self?.scanner?.stopScanning()
                                let paths = url!.pathComponents
                                let firstPath = paths[1]
                                if Session.shared.isAuthenticated {
                                    if paths.count == 3 && firstPath == "instances" {
                                        let number = paths.filter { $0.isNumber }.map { Int($0) }.filter{ $0 != nil }.map{ $0! }.first
                                        guard let value = number else {
                                            self?.showErorrAlert()
                                            return
                                        }
                                        self?.performSegue(withIdentifier: "showRequestBookstopOrganization", sender: value)
                                    } else if paths.count == 3 && firstPath == "gat_up" {
                                        let number = paths.filter { $0.isNumber }.map { Int($0) }.filter{ $0 != nil }.map{ $0! }.first
                                        guard let value = number else {
                                            self?.showErorrAlert()
                                            return
                                        }
                                        let bookstop = Bookstop()
                                        bookstop.id = value
                                        BookstopNetworkService.shared.info(bookstop: bookstop)
                                            .catchErrorJustComplete()
                                            .subscribe(onNext: { bookstop in
                                                if bookstop.id != 0 {
                                                    self?.showJoin?(value)
                                                } else {
                                                    self?.showErorrAlert()
                                                }
                                            }).disposed(by: self!.disposeBag)
                                    }
                                    else if paths.count == 3 && firstPath == "users" {     /* add scan user,member */
                                        let string = paths[2]
                                        let properString = string.removingPercentEncoding!
                                        if Repository<UserPrivate, UserPrivateObject>.shared.get()?.profile?.username == properString {
                                            let user = UserPrivate()
                                            user.profile!.username = properString
                                            let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                                            let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                                            vc.isShowButton.onNext(true)
                                            vc.userPrivate.onNext(user)
                                            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                                        }
                                        else {
                                            let user = UserPublic()
                                            user.profile.username = string
                                            let storyboard = UIStoryboard(name: "ScanUserProfile", bundle: nil)
                                            let vc = storyboard.instantiateViewController(withIdentifier: ScanUserSuccessViewController.className) as! ScanUserSuccessViewController
                                            vc.userPublic.onNext(user)
                                            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                                        }
                                    }
                                    else if paths.count == 3 && firstPath == "reviews" {  /* add scan review */
                                        let number = paths.filter { $0.isNumber }.map { Int($0) }.filter{ $0 != nil }.map{ $0! }.first
                                        guard let value = number else {
                                            self?.showErorrAlert()
                                            return
                                        }
                                        let review = Review()
                                        review.reviewId = value
                                        let storyboard = UIStoryboard(name: "BookDetail", bundle: nil)
                                        let vc = storyboard.instantiateViewController(withIdentifier: ReviewViewController.className) as! ReviewViewController
                                        vc.review.onNext(review)
                                        UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                                    }
                                    else {
                                        self?.scanner?.stopScanning()
                                        let ok = ActionButton(titleLabel: Gat.Text.BookDetail.OK_ALERT_TITLE.localized()) { [weak self] in
                                            self?.navigationController?.popViewController(animated: true)
                                        }
                                        AlertCustomViewController.showAlert(title: "URL ERROR", message: "Url is not suitable", actions: [ok], in: self!)
                                    }
                                    
                                } else {
                                    HandleError.default.loginAlert()
                                }
                            }
                        }
                        else {
                            self?.scanner?.stopScanning()
                            self?.isbnBook.onNext(result)
                        }
                    case .join:
                        if let url = URL(string: result) {
                            self?.scanner?.stopScanning()
                            let number = url.pathComponents.filter { $0.isNumber }.map { Int($0) }.filter{ $0 != nil }.map{ $0! }.first
                            guard let value = number, let handle = self?.joinHandler?(value) else { return }
                            if handle {
                                self?.showJoin?(value)
                            } else {
                                self?.showErorrAlert()
                            }
                        }
                    case .username:
                        let url = URL(string: result)
                        self?.scanner?.stopScanning()
                        let paths = url!.pathComponents
                        let user = UserPublic()
                        user.profile.username = paths.last ?? ""
                        let storyboard = UIStoryboard(name: "ScanUserProfile", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: ScanUserSuccessViewController.className) as! ScanUserSuccessViewController
                        vc.userPublic.onNext(user)
                        UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                    }
                }
                
            })
        } catch {
            print("Không thể quét được mã: ", error.localizedDescription)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
                let vc = segue.destination as? BookDetailViewController
                vc?.bookInfo.onNext(sender as! BookInfo)
            }
        }
        if segue.identifier == "showRequestBookstopOrganization" {
            let vc = segue.destination as? RequestBookstopOrganizationViewController
            let instance = Instance()
            instance.id = sender as! Int
            vc?.instance.onNext(instance)
        }
        if segue.identifier == "showVisitorProfile" {    /* new scan user */
            let vc = segue.destination as? UserVistorViewController
            let user = UserPublic()
            user.profile.id = sender as! Int
            vc?.userPublic.onNext(user)
        }
    }
    
}

extension BarcodeContainerViewController {
    enum ScanBarcodeType {
        case all
        case book
        case join
        case username
    }
}
