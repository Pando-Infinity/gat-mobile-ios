//
//  ViewController.swift
//  gat
//
//  Created by HungTran on 2/12/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift
import Firebase
import GoogleSignIn

class LoginViewController: UIViewController {
    
    class var segueIdentifier: String { "showLogin" }
    
    //MARK: - UI Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var messageEmailLabel: UILabel!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var messagePasswordLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var socialLoginLabel: UILabel!
    @IBOutlet weak var facebookLoginButton: UIButton!
    @IBOutlet weak var appleLoginButton:UIButton!
    @IBOutlet weak var googleLoginButton: UIButton!
    @IBOutlet weak var forgetPasswordButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var showPasswordButton: UIButton!
    
    var alert: UIAlertController!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    //MARK: - Private Data Properties
    fileprivate var presenter: LoginPresenter!
    fileprivate let disposeBag = DisposeBag()
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.presenter = AppleLoginPresenter(router: SimpleLoginRouter(viewController: self))
        } else {
            self.presenter = SimpleLoginPresenter(router: SimpleLoginRouter(viewController: self))
        }
        self.setupUI()
        self.event()
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.btnSignWithAppleOnlyAppearForIOS13orHigher()
        self.titleLabel.text = Gat.Text.Login.LOGIN_TITLE.localized()
        self.passwordLabel.text = Gat.Text.Login.PASSWORD_PLACEHOLDER.localized()
        self.passwordTextField.attributedPlaceholder = .init(string: Gat.Text.Login.PASSWORD_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.emailTextField.attributedPlaceholder = .init(string: "Email", attributes:  [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.loginButton.setTitle(Gat.Text.Login.LOGIN_TITLE.localized(), for: .normal)
        self.loginButton.cornerRadius(radius: 4.0)
        self.facebookLoginButton.cornerRadius(radius: 4.0)
        self.appleLoginButton.cornerRadius(radius: 4.0)
        self.googleLoginButton.cornerRadius(radius: 4.0)
        
        self.forgetPasswordButton.setTitle(Gat.Text.Login.FORGOT_PASSWORD_TITLE.localized(), for: .normal)
        self.socialLoginLabel.text = Gat.Text.Login.LOGIN_SOCIAL_TITLE.localized()
        
        let text = "\(Gat.Text.Login.HAVE_NOT_ACCOUNT.localized()) \(Gat.Text.Login.REGISTER_NOW.localized())"
        let attributedString = NSMutableAttributedString(string: text, attributes: [
          .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
          .foregroundColor: UIColor(white: 155.0 / 255.0, alpha: 1.0),
          .kern: 0.17
        ])
        
        attributedString.addAttributes([
          .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
          .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
        ], range: (text as NSString).range(of: Gat.Text.Login.REGISTER_NOW.localized()))
        
        self.registerButton.setAttributedTitle(attributedString, for: .normal)
        self.setupLoading()
        self.messageEmailLabel.text = Gat.Text.Login.MESSAGE_EMAIL.localized()
        self.messagePasswordLabel.text = Gat.Text.Login.MESSAGE_PASSWORD.localized()
        self.hideMessageIfNeeded(textField: self.emailTextField, message: self.messageEmailLabel, filter: { !$0.isEmpty && $0.isValidEmail() })
        self.hideMessageIfNeeded(textField: self.passwordTextField, message: self.messagePasswordLabel, filter: { !$0.isEmpty })
        Observable
            .of(self.emailTextField.rx.controlEvent(.editingDidBegin), self.passwordTextField.rx.controlEvent(.editingDidBegin))
            .merge()
            .map { true }
            .bind(to: self.messageEmailLabel.rx.isHidden, self.messagePasswordLabel.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func hideMessageIfNeeded(textField: UITextField, message: UILabel, filter: @escaping (String) -> Bool) {
        Observable.of(textField.rx.controlEvent(.editingDidEnd), self.loginButton.rx.tap)
            .merge()
            .withLatestFrom(textField.rx.text.orEmpty.asObservable())
            .map(filter)
            .bind(to: message.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupLoading() {
        self.alert = UIAlertController(title: nil, message: "PLEASE_WAIT".localized(), preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();

        self.alert.view.addSubview(loadingIndicator)
        self.presenter.loading.map { !$0 }.bind(to: self.view.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
        self.presenter.loading.withLatestFrom(Observable.just(self), resultSelector: { ($0, $1)})
        .subscribe(onNext: { (status, vc) in
            if status {
                vc.present(vc.alert, animated: true, completion: nil)
            } else {
                vc.alert.dismiss(animated: true) {
                    vc.presenter.showError()
                }
            }
            }).disposed(by: disposeBag)
    }

    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.backEvent()
        self.loginEmailEvent()
        self.loginSocialEvent()
        self.keyboardEvent()
        self.showPasswordEvent()
        self.registerEvent()
        self.forgotPasswordEvent()
        if #available(iOS 13.0, *) {
            self.loginAppleEvent()
        }
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func loginEmailEvent() {
        self.loginButton.rx.tap
            .withLatestFrom(Observable.combineLatest(self.emailTextField.rx.text.orEmpty.asObservable(), self.passwordTextField.rx.text.orEmpty.asObservable()))
            .map { Credentials(email: $0, password: $1) }
            .flatMap(self.presenter.signIn(credentials:))
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func loginSocialEvent() {
        Observable.of(
            self.facebookLoginButton.rx.tap.map { _ in SocialType.facebook },
            self.googleLoginButton.rx.tap.map { _ in SocialType.google }
        )
            .merge()
            .flatMap(self.presenter.signIn(social:))
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    @available(iOS 13.0, *)
    fileprivate func loginAppleEvent() {
        self.appleLoginButton.rx.tap.subscribe(onNext: self.presenter.signInApple)
        .disposed(by: disposeBag)
    }
    
    fileprivate func keyboardEvent() {
        Observable.of(
            self.emailTextField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
            self.passwordTextField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
            self.view.rx.tapGesture().when(.recognized).map { _ in },
            self.loginButton.rx.tap.asObservable()
        ).merge()
            .subscribe(onNext: { [weak self] (_) in
                self?.view.endEditing(false)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func btnSignWithAppleOnlyAppearForIOS13orHigher(){
        if #available(iOS 13.0, *) {
            self.appleLoginButton.isHidden = false
        } else {
            self.appleLoginButton.isHidden = true
            self.facebookLoginButton.bottomAnchor.constraint(equalTo: self.registerButton.topAnchor, constant: -24.0).isActive = true
        }
    }
    
    fileprivate func showPasswordEvent() {
        let shared = self.showPasswordButton.rx.tap.withLatestFrom(Observable.just(self.passwordTextField).compactMap { $0 })
            .map { !$0.isSecureTextEntry }
            .share()
        
        shared
            .bind { [weak self] (value) in
                self?.passwordTextField.isSecureTextEntry = value
            }.disposed(by: self.disposeBag)
        
        
        shared.map { $0 ? #imageLiteral(resourceName: "eyeSlash") : #imageLiteral(resourceName: "eyeOn") }.bind(to: self.showPasswordButton.rx.image(for: .normal)).disposed(by: self.disposeBag)
    }
    
    fileprivate func registerEvent() {
        self.registerButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.performSegue(withIdentifier: RegisterViewController.segueIdentifier, sender: nil)
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func forgotPasswordEvent() {
        self.forgetPasswordButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.performSegue(withIdentifier: "showForgotPassword", sender: nil)
            }).disposed(by: self.disposeBag)
    }
    
    //MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showForgotPassword" {
            let vc = segue.destination as? ForgotPasswordViewController
            vc?.email.onNext(self.emailTextField.text ?? "")
            
        }
    }
}

//MARK: - Extension
extension LoginViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

