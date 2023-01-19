//
//  JoinBookstopViewController.swift
//  gat
//
//  Created by Vũ Kiên on 16/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class JoinBookstopViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    let bookstop: BehaviorSubject<Bookstop> = .init(value: Bookstop())
    let isUpdateInfo: BehaviorSubject<Bool> = .init(value: false)
    var goToBookstopInfo: Bool = false
    var gotoBookstop: ((Bookstop) -> Void)?
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.getData()
        self.setupUI()
        self.sendRequest()
        self.event()
    }
    
    // MARK: - REQUEST
    fileprivate func sendRequest() {
        self.joinButton
            .rx
            .controlEvent(.touchUpInside)
            .flatMapLatest { [weak self] (_) -> Observable<(Bookstop, String?, RequestBookstopStatus)> in
                return Observable<(Bookstop, String?, RequestBookstopStatus)>
                    .combineLatest(
                        self?.bookstop ?? Observable.empty(),
                        self?.textView.rx.text.asObservable() ?? Observable.empty(),
                        Observable<RequestBookstopStatus>.just(.join),
                        resultSelector: { ($0, $1, $2) }
                )
            }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.view.isUserInteractionEnabled = false
            })
            .flatMapLatest { [weak self] (bookstop, intro, status) in
                BookstopNetworkService
                    .shared
                    .request(in: bookstop, with: status, intro: intro)
                    .catchError { [weak self] (error) -> Observable<()> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self?.view.isUserInteractionEnabled = true
                        HandleError.default.showAlert(with: error)
                        return Observable<()>.empty()
                    }
            }
            .flatMapLatest { [weak self] _ in
                UserNetworkService
                    .shared
                    .privateInfo()
                    .catchError({ [weak self] (error) -> Observable<UserPrivate> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self?.navigationController?.popViewController(animated: true)
                        return Observable.empty()
                    })
            }
            .flatMap {
                Observable<UserPrivate>
                    .combineLatest(
                        Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                        Observable<UserPrivate>.just($0),
                        resultSelector: { (old, new) -> UserPrivate in
                            old.update(new: new)
                            return old
                    })
                
            }
            .flatMapLatest { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.isUpdateInfo.onNext(true)
                self?.showAlert()
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Data
    fileprivate func getData() {
        self.bookstop.filter { $0.id != 0 && $0.profile!.name.isEmpty }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .info(bookstop: $0)
                    .catchError { (error) -> Observable<Bookstop> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .subscribe(onNext: self.bookstop.onNext)
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = Gat.Text.JoinBookstop.TITLE.localized()
        self.setupBookstopDetail()
        self.setupJoinButton()
    }
    
    fileprivate func setupBookstopDetail() {
        self.bookstop
            .subscribe(onNext: { [weak self] (bookstop) in
                self?.view.layoutIfNeeded()
                self?.imageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookstop.profile!.imageId))!, placeholderImage: DEFAULT_USER_ICON)
                self?.imageView.circleCorner()
                self?.nameLabel.text = bookstop.profile?.name
                self?.addressLabel.text = bookstop.profile?.address
                self?.messageLabel.text = String.init(format: Gat.Text.JoinBookstop.REQUEST_MESSAGE.localized(), bookstop.profile!.name, bookstop.profile!.name)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupJoinButton() {
        self.joinButton.layer.borderColor = #colorLiteral(red: 0.8117647059, green: 0.9333333333, blue: 1, alpha: 1)
        self.joinButton.layer.borderWidth = 1.2
        self.joinButton.cornerRadius(radius: 10)
        self.joinButton.setTitle(Gat.Text.RequestBookstop.JOIN_TITLE.localized(), for: .normal)
        Observable.just(Session.shared.isAuthenticated)
            .map { !$0 }
            .subscribe(self.joinButton.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showAlert() {
        let ok = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized()) { [weak self] in
            self?.navigate()
        }
        
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.NOTIFICATION_TITLE.localized(), message: Gat.Text.JoinBookstop.JOIN_BOOKSTOP_SUCCESS_MESSAGE.localized(), actions: [ok], in: self)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.view.rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.hideKeyboardWhenTappedAround()
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BookstopOriganizationViewController.segueIdentifier {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        }
    }
    
    fileprivate func navigate() {
        if self.gotoBookstop != nil {
            self.navigationController?.popViewController(animated: true)
            self.gotoBookstop?(try! self.bookstop.value())
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

}
