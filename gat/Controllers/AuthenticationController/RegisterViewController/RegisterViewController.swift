//
//  RegisterViewController.swift
//  gat
//
//  Created by HungTran on 2/17/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RealmSwift
import RxSwift
import Firebase
import GoogleSignIn

class RegisterViewController: UIViewController {
    
    class var segueIdentifier: String { "showRegister" }
    
    //MARK: - UI Properties
    /**Các nút đăng ký bằng mạng xã hội*/
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var confirmPasswordLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var socialLoginLabel: UILabel!
    @IBOutlet weak var loginbutton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var facebookLoginButton: UIButton!
    @IBOutlet weak var appleLoginButton:UIButton!
    @IBOutlet weak var googleLoginButton: UIButton!
    @IBOutlet weak var showPasswordButton: UIButton!
    @IBOutlet weak var showForgotButton: UIButton!
    @IBOutlet weak var messageEmailLabel: UILabel!
    @IBOutlet weak var messagePasswordLabel: UILabel!
    @IBOutlet weak var messageConfirmLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    fileprivate var presenter: RegisterPresenter!
    fileprivate let disposeBag = DisposeBag()
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.presenter = AppleSimpleRegisterPresenter(router: SimpleRegisterRouter(viewController: self))
        } else {
            self.presenter = SimpleRegisterPresenter(router: SimpleRegisterRouter(viewController: self))
        }
        self.setupUI()
        self.event()
    }
    
    //MARK: - UI
    private func setupUI() {
        self.btnSignWithAppleOnlyAppearForIOS13orHigher()
        self.titleLabel.text = Gat.Text.Register.REGISTER_TITLE.localized()
        self.passwordLabel.text = Gat.Text.Register.PASSWORD_PLACEHOLDER.localized()
        self.confirmPasswordLabel.text = Gat.Text.Register.CONFIRM_PASSWORD.localized()
        self.emailTextField.attributedPlaceholder = .init(string: Gat.Text.Register.EMAIL_ADDRESS_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.passwordTextField.attributedPlaceholder = .init(string: Gat.Text.Register.PASSWORD_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.confirmTextField.attributedPlaceholder = .init(string: Gat.Text.Register.COMFIRM_PASSWORD_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        let text = "\(Gat.Text.Register.ALREADY_HAVE_ACCOUNT.localized()) \(Gat.Text.Register.LOGIN_NOW.localized())"
        let attributedString = NSMutableAttributedString(string: text, attributes: [
          .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
          .foregroundColor: UIColor(white: 155.0 / 255.0, alpha: 1.0),
          .kern: 0.17
        ])
        attributedString.addAttributes([
          .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
          .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
        ], range: (text as NSString).range(of: Gat.Text.Register.LOGIN_NOW.localized()))
        self.loginbutton.setAttributedTitle(attributedString, for: .normal)
        self.registerButton.cornerRadius(radius: 4.0)
        self.googleLoginButton.cornerRadius(radius: 4.0)
        self.facebookLoginButton.cornerRadius(radius: 4.0)
        self.appleLoginButton.cornerRadius(radius: 4.0)
        self.socialLoginLabel.text = Gat.Text.Login.LOGIN_SOCIAL_TITLE.localized()
        self.registerButton.setTitle(Gat.Text.Register.REGISTER_TITLE.localized(), for: .normal)
        self.presenter.loading.map { !$0 }.bind(to: self.view.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
        
        Observable
        .of(self.emailTextField.rx.controlEvent(.editingDidBegin), self.passwordTextField.rx.controlEvent(.editingDidBegin),
            self.confirmTextField.rx.controlEvent(.editingDidBegin))
        .merge()
        .map { true }
            .bind(to: self.messageEmailLabel.rx.isHidden, self.messagePasswordLabel.rx.isHidden, self.messageConfirmLabel.rx.isHidden)
        .disposed(by: self.disposeBag)
        
        self.messageEmailLabel.text = Gat.Text.Login.MESSAGE_EMAIL.localized()
        self.messagePasswordLabel.text = Gat.Text.Login.MESSAGE_PASSWORD.localized()
        
        self.hideMessageIfNeeded(textField: self.emailTextField, message: self.messageEmailLabel, filter: { !$0.isEmpty && $0.isValidEmail() })
        self.hideMessageIfNeeded(textField: self.passwordTextField, message: self.messagePasswordLabel, filter: { !$0.isEmpty })
        let shared = Observable
            .of(self.confirmTextField.rx.controlEvent(.editingDidEnd), self.registerButton.rx.tap)
            .merge()
            .withLatestFrom(Observable.combineLatest(self.confirmTextField.rx.text.orEmpty.asObservable(), self.passwordTextField.rx.text.orEmpty.asObservable()))
            .share()
        
        shared.map { !$0.isEmpty && $0 == $1 }.bind(to: self.messageConfirmLabel.rx.isHidden).disposed(by: self.disposeBag)
        shared.map { (confirm, password) -> String in
            if confirm.isEmpty { return Gat.Text.Register.CONFIRM_EMPTY_MESSAGE.localized() }
            if confirm != password { return Gat.Text.Register.COMFIRM_NOT_EQUAL_PASSWORD_MESSAGE.localized() }
            return ""
        }.bind(to: self.messageConfirmLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    fileprivate func hideMessageIfNeeded(textField: UITextField, message: UILabel, filter: @escaping (String) -> Bool) {
        Observable.of(textField.rx.controlEvent(.editingDidEnd), self.registerButton.rx.tap)
            .merge()
            .withLatestFrom(textField.rx.text.orEmpty.asObservable())
            .map(filter)
            .bind(to: message.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    private func event() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.backEvent()
        self.keyboardEvent()
        self.showPasswordEvent()
        self.signUpEvent()
        self.socialRegisterEvent()
        if #available(iOS 13.0, *) {
            self.loginAppleEvent()
        }
    }
    
    fileprivate func backEvent() {
        Observable.of(self.backButton.rx.tap.asObservable(), self.loginbutton.rx.tap.asObservable())
        .merge()
            .withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func signUpEvent() {
        self.registerButton.rx.tap
            .withLatestFrom(Observable.combineLatest(self.emailTextField.rx.text.orEmpty.asObservable(), self.passwordTextField.rx.text.orEmpty.asObservable(), self.confirmTextField.rx.text.orEmpty.asObservable()))
            .map { Credentials(email: $0, password: $1, confirmPassword: $2) }
            .flatMap(self.presenter.signUp(credentials:))
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func btnSignWithAppleOnlyAppearForIOS13orHigher(){
        if #available(iOS 13.0, *) {
            self.appleLoginButton.isHidden = false
        } else {
            self.appleLoginButton.isHidden = true
            self.facebookLoginButton.bottomAnchor.constraint(equalTo: self.loginbutton.topAnchor, constant: -24.0).isActive = true
        }
    }
    
    fileprivate func keyboardEvent() {
        Observable.of(
            self.emailTextField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
            self.passwordTextField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
            self.confirmTextField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
            self.view.rx.tapGesture().when(.recognized).map { _ in },
            self.registerButton.rx.tap.asObservable()
        ).merge()
            .subscribe(onNext: { [weak self] (_) in
                self?.view.endEditing(false)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showPasswordEvent() {
        self.showPassword(button: self.showPasswordButton, textField: self.passwordTextField)
        self.showPassword(button: self.showForgotButton, textField: self.confirmTextField)
    }
    
    fileprivate func showPassword(button: UIButton, textField: UITextField) {
        let shared = button.rx.tap.withLatestFrom(Observable.just(textField).compactMap { $0 })
            .map { !$0.isSecureTextEntry }
            .share()
        
        shared
            .bind { (value) in
                textField.isSecureTextEntry = value
            }.disposed(by: self.disposeBag)
        
        
        shared.map { $0 ? #imageLiteral(resourceName: "eyeSlash") : #imageLiteral(resourceName: "eyeOn") }.bind(to: button.rx.image(for: .normal)).disposed(by: self.disposeBag)
    }
    
    fileprivate func socialRegisterEvent() {
        Observable.of(
            self.facebookLoginButton.rx.tap.map { _ in SocialType.facebook },
            self.googleLoginButton.rx.tap.map { _ in SocialType.google }
        )
            .merge()
            .flatMap(self.presenter.signUp(social: ))
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    @available(iOS 13.0, *)
    fileprivate func loginAppleEvent() {
        self.appleLoginButton.rx.tap.subscribe(onNext: self.presenter.signInApple)
        .disposed(by: disposeBag)
    }
    
    // MARK: -Navigator
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}

extension RegisterViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
