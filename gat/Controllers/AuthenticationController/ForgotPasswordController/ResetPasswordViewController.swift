//
//  ResetPasswordViewController.swift
//  gat
//
//  Created by HungTran on 3/8/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import RxCocoa
import Firebase

/* Todo
 + [OK] Hiển thị email từ màn hình confirm gửi sang
 + [OK] Gửi mật khẩu mới kèm theo mã confirm từ màn hình confirm để đổi sang mật khẩu mới
 + [OK] Lưu lại loginToken và chuyển ra màn Home
 + Hiển thị Loading mạng
 */

class ResetPasswordViewController: UIViewController {
    //MARK: - UI Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var changePassword: UIButton!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var changePassLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Public Data Properties
    let tokenVerify: BehaviorSubject<String> = .init(value: "")
    let senderEmail: BehaviorSubject<String> = .init(value: "")
    private let disposeBag = DisposeBag()
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.request()
        self.setupUI()
    }
    
    fileprivate func request() {
        self.changePassword
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.newPassword.rx.text.orEmpty.asObservable())
            .filter { !$0.isEmpty }
            .flatMapLatest { [weak self] (password) -> Observable<(String, String, String)> in
                return Observable<(String, String, String)>
                    .combineLatest(
                        Observable<String>.just(password),
                        self?.tokenVerify ?? Observable.empty(),
                        Observable<String>.just(UIDevice.current.identifierForVendor?.uuidString ?? ""),
                        resultSelector: { ($0, $1, $2) }
                    )
            }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.view.isUserInteractionEnabled = false
            })
            .flatMapLatest { [weak self] (password, token, uuid) -> Observable<(String, String?)> in
                return UserNetworkService
                    .shared
                    .changePassword(new: password, token: token, uuid: uuid)
                    .catchError({ [weak self] (error) -> Observable<(String, String?)> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self?.view.isUserInteractionEnabled = true
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
            .map { (token, _) in token }
            .do(onNext: { (token) in
                Session.shared.accessToken = token
            })
            .flatMap({ (token) -> Observable<UserPrivate> in
                return UserNetworkService.shared.privateInfo(with: token)
                    .catchError { (error) -> Observable<UserPrivate> in
                        HandleError.default.showAlert(with: error)
                        Session.shared.accessToken = nil
                        return .empty()
                    }
            })
            .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .do(onNext: { (_) in 
                MessageService.shared.configure()
            })
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.view.isUserInteractionEnabled = true
                FirebaseBackground.shared.registerFirebaseToken()
                self?.goToHome()
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    private func setupUI() {
        self.titleLabel.text = Gat.Text.ResetPassword.FORGOT_PASSWORD_TITLE.localized()
        self.changePassLabel.text = Gat.Text.ResetPassword.CHANGE_PASSWORD_TITLE.localized()
        self.newPassword.placeholder = Gat.Text.ResetPassword.NEW_PASSWORD_PLACEHOLDER.localized()
        self.messageLabel.text = Gat.Text.ResetPassword.MESSAGE_FORGOT.localized()
        self.messageLabel.sizeToFit()
        self.hideKeyboardWhenTappedAround()
        self.senderEmail.bind(to: self.email.rx.text).disposed(by: self.disposeBag)
    }
    
    /**Kích hoạt tương tác các nút trong giao diện*/
    private func enableStatus(_ status: Bool) {
        self.newPassword.isUserInteractionEnabled = status
        self.newPassword.isEnabled = status
        self.changePassword.isUserInteractionEnabled = status
    }
    
    fileprivate func goToHome() {
        let storyboard = UIStoryboard.init(name: Gat.Storyboard.Main, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: TabBarController.className)
        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = vc
    }
    
    // MARK: - Event
    @IBAction func Back(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
}
