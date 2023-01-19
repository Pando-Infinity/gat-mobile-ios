//
//  ChangePasswordViewController.swift
//  gat
//
//  Created by HungTran on 5/6/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift
import RxCocoa
import FirebaseAnalytics

class ChangePasswordViewController: UIViewController {
    //MARK: - UI Properties
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var currentPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var forgetPasswordButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var forgotLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private var disposeBag = DisposeBag()
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupEvent()
    }
    
    //MARK: - Event
    private func setupEvent() {
        self.setupBackButtonEvent()
        self.setupForgetPasswordButtonEvent()
        self.setupIsModifiedEvent()
        self.setupSaveButtonEvent()
    }
    
    private func setupBackButtonEvent() {
        self.backButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.currentPassword.rx.text.orEmpty.asObservable())
            .withLatestFrom(self.newPassword.rx.text.orEmpty.asObservable(), resultSelector: { ($0, $1) })
            .withLatestFrom(self.confirmPassword.rx.text.orEmpty.asObservable(), resultSelector: { ($0.0, $0.1, $1) })
            .map { !$0.isEmpty || !$1.isEmpty || !$2.isEmpty }
            .subscribe(onNext: { [weak self] (status) in
//                if status {
//
//                } else {
//
//                }
                self?.checkChangeInfo()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func checkChangeInfo() {
        if let current = self.currentPassword.text, let new = self.newPassword.text, let confirm = self.confirmPassword.text {
            if !current.isEmpty || !new.isEmpty || !confirm.isEmpty {
                UIHelper.shared.showAlert(on: self, type: .ModifiedData, firstAction: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func setupForgetPasswordButtonEvent() {
        self.forgetPasswordButton
            .rx
            .tap
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.performSegue(withIdentifier: Gat.Segue.openForgetPassword, sender: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setupIsModifiedEvent() {
        Observable<Bool>
            .combineLatest(
                self.newPassword.rx.text.orEmpty.asObservable(),
                self.confirmPassword.rx.text.orEmpty.asObservable(),
                resultSelector: { !$0.isEmpty && !$1.isEmpty }
            )
            .subscribe(self.saveButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
        
    }
    
    private func setupSaveButtonEvent() {
        self.saveButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.currentPassword.rx.text.orEmpty.asObservable())
            .withLatestFrom(self.newPassword.rx.text.orEmpty.asObservable(), resultSelector: { ($0, $1) })
            .withLatestFrom(self.confirmPassword.rx.text.orEmpty.asObservable(), resultSelector: { ($0.0, $0.1, $1) })
            .do(onNext: { [weak self] (_, newPassword, confirmPassword) in
                if newPassword != confirmPassword {
                    self?.showAlert()
                }
            })
            .filter { (_, newPassword, confirmPassword) in newPassword == confirmPassword }
            .map { (current, new, _) in (current, new) }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.view.isUserInteractionEnabled = false
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap { [weak self] (current, new) in
                return UserNetworkService
                    .shared
                    .update(newPassword: new, currentPassword: current, uuid: UIDevice.current.identifierForVendor?.uuidString ?? "")
                    .catchError { [weak self] (error) -> Observable<(String, String?)> in
                        self?.view.isUserInteractionEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .flatMap({ (token, password) -> Observable<String?> in
                Session.shared.accessToken = token
                return Observable.just(password)
            })
            .do(onNext: { (password) in
//                if let password = password {
//                    UserDefaults.standard.set(password, forKey: "password")
//                }
            })
            .subscribe(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    private func setupUI() {
        self.titleLabel.text = Gat.Text.ChangePassword.CHANGE_PASSWORD_TITLE.localized()
        self.currentPassword.attributedPlaceholder = .init(string: Gat.Text.ChangePassword.PRESENT_PASSWORD_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.newPassword.attributedPlaceholder = .init(string: Gat.Text.ChangePassword.NEW_PASSWORD_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.confirmPassword.attributedPlaceholder = .init(string: Gat.Text.ChangePassword.CONFIRM_PASSWORD_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.forgotLabel.text = Gat.Text.ChangePassword.FORGOT_PASSWORD_TITLE.localized()
        self.hideKeyboardWhenTappedAround()
        self.setupActiveInputUI()
    }
    
    private func setupActiveInputUI() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        Observable<Bool>
            .combineLatest(
                self.currentPassword.rx.text.orEmpty.asObservable(),
                self.newPassword.rx.text.orEmpty.asObservable(),
                self.confirmPassword.rx.text.orEmpty.asObservable(),
                resultSelector: { ($0.isEmpty && $1.isEmpty && $2.isEmpty )}
            )
            .subscribe(onNext: { [weak self] (status) in
                self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = status
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showAlert() {
        let ok = ActionButton.init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.NOTIFICATION_TITLE.localized(), message: Gat.Text.ChangePassword.PASSWORD_MESSAGE.localized(), actions: [ok], in: self)
    }
    
    //MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
                case Gat.Segue.openForgetPassword:
                    let vc = segue.destination as! ForgotPasswordViewController
                    Repository<UserPrivate, UserPrivateObject>
                        .shared
                        .getFirst()
                        .map { $0.profile!.email }
                        .subscribe(vc.email)
                        .disposed(by: self.disposeBag)
//                    vc.isLockEmail.onNext(true)
                default: break
            }
        }
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
}

//MARK: - Extension
extension ChangePasswordViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
