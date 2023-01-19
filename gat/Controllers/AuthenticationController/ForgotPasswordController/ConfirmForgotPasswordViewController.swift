//
//  ConfirmForgotPasswordViewController.swift
//  gat
//
//  Created by HungTran on 3/8/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Firebase
import FirebaseAnalytics

/* Todo
 + [OK] Hiển thị email từ màn hình confirm gửi sang
 + [OK] Gửi lên server code xác thực kèm theo requestResetPassword
 + Hiển thị Loading mạng
 */

class ConfirmForgotPasswordViewController: UIViewController {
    //MARK: - UI Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var confirmCodeLabel: UITextField!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var changePassLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Public Data Properties
    let tokenResetPassword: BehaviorSubject<String> = .init(value: "")
    let senderEmail: BehaviorSubject<String> = .init(value: "")
    
    //MARK: - Private Data Properties
    private let disposeBag = DisposeBag()
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.request()
    }
    
    // MARK: - SendRequest
    fileprivate func request() {
        self.changePasswordButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.confirmCodeLabel.rx.text.orEmpty.asObservable())
            .filter { !$0.isEmpty }
            .flatMapLatest({ [weak self] (code) -> Observable<(String, String)> in
                return Observable<(String, String)>.combineLatest(Observable<String>.just(code), self?.tokenResetPassword ?? Observable.empty(), resultSelector: { ($0, $1) })
            })
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.enableStatus(false)
            })
            .flatMapLatest { [weak self] (code, token) -> Observable<String> in
                return UserNetworkService
                    .shared
                    .verify(code: code, tokenResetPassword: token)
                    .catchError({ [weak self] (error) -> Observable<String> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self?.enableStatus(true)
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { [weak self] (code) in
                self?.performSegue(withIdentifier: Gat.Segue.openEnterNewPassword, sender: code)
            })
            .disposed(by: self.disposeBag)
    }
    
    @IBAction func Back(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - UI
    private func setupUI() {
        self.titleLabel.text = Gat.Text.ConfirmPassword.FORGOT_PASSWORD_TITLE.localized()
        self.changePassLabel.text = Gat.Text.ConfirmPassword.CHANGE_PASSWORD_TITLE.localized()
        self.messageLabel.text = Gat.Text.ConfirmPassword.MESSAGE_FORGOT.localized()
        self.messageLabel.sizeToFit()
        self.confirmCodeLabel.attributedPlaceholder = .init(string: Gat.Text.ConfirmPassword.CODE_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.hideKeyboardWhenTappedAround()
        self.senderEmail
            .bind(to: self.email.rx.text)
            .disposed(by: self.disposeBag)
    }
    /**Kích hoạt tương tác các nút trong giao diện*/
    private func enableStatus(_ status: Bool) {
        self.confirmCodeLabel.isUserInteractionEnabled = status
        self.confirmCodeLabel.isEnabled = status
        self.changePasswordButton.isUserInteractionEnabled = status
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    //MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.openEnterNewPassword {
            let vc = segue.destination as! ResetPasswordViewController
            self.senderEmail.subscribe(vc.senderEmail).disposed(by: self.disposeBag)
            vc.tokenVerify.onNext(sender as! String)
        }
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
}

//MARK: - Extension
extension ConfirmForgotPasswordViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

