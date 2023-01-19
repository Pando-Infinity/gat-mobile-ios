//
//  ForgetPasswordViewController.swift
//  gat
//
//  Created by HungTran on 3/8/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Firebase

/**Todo
 + Hiển thị Loading mạng
 */
class ForgotPasswordViewController: UIViewController {
    //MARK: - UI Properties
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var sendEmailLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    let email: BehaviorSubject<String> = .init(value: "")
    let isLockEmail: BehaviorSubject<Bool> = .init(value: false)
    
    let googleService = GoogleService()
    
    //MARK: - Private Data Properties
    private let disposeBag = DisposeBag()
//    private var verifyCode = ""
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.handler()
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Send Data
    fileprivate func request() -> Observable<(String, SocialProfile?)> {
        return self.sendButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.isLockEmail)
            .flatMapLatest { [weak self] (isLock) -> Observable<String> in
                if isLock {
                    return self?.email ?? Observable.empty()
                } else {
                    return Observable<String>.just(self?.emailLabel.text ?? "")
                }
            }
            .filter { !$0.isEmpty }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.view.isUserInteractionEnabled = false
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest { [weak self] (email) -> Observable<(String, SocialProfile?)> in
                return UserNetworkService
                    .shared
                    .sendResetPassword(to: email)
                    .catchError({ [weak self] (error) -> Observable<(String, SocialProfile?)> in
                        self?.view.isUserInteractionEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
        }
    }
    
    fileprivate func handler() {
        let request = self.request().share()
        self.handlerResetPasswordLoginEmail(request: request)
        self.handlerResetPasswordLoginSocial(request: request)
    }
    
    fileprivate func handlerResetPasswordLoginEmail(request: Observable<(String, SocialProfile?)>) {
        request
            .filter { $0.1 == nil }
            .map { $0.0 }
            .subscribe(onNext: { [weak self] (code) in
                self?.view.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.performSegue(withIdentifier: Gat.Segue.openConfirmPassword, sender: code)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func handlerResetPasswordLoginSocial(request: Observable<(String, SocialProfile?)>) {
        self.login(request: request).flatMapLatest { (token, type) -> Observable<(AccessTokenEmail, SocialProfile?, LoginType)> in
            let accessToken = AccessTokenEmail()
            accessToken.token = token
            switch type {
            case .email(_, _): return .empty()
            case .facebook(_):
                return Observable<(AccessTokenEmail, SocialProfile?, LoginType)>
                    .combineLatest(
                        Observable<AccessTokenEmail>.just(accessToken),
                        FacebookService.shared.profile(),
                        FacebookService.shared.token,
                        Observable<LoginType>.just(type),
                        resultSelector: { (accessToken, profile, facebookToken, loginType) -> (AccessTokenEmail, SocialProfile?, LoginType) in
                            accessToken.facebookToken = facebookToken
                            return (accessToken, profile, loginType)
                    })
            case .google(_):
                return Observable<(AccessTokenEmail, SocialProfile?, LoginType)>
                    .combineLatest(
                        Observable<AccessTokenEmail>.just(accessToken),
                        self.googleService.profileObservable,
                        self.googleService.tokenObservable,
                        Observable<LoginType>.just(type),
                        resultSelector: { (accessToken, profile, token, type) -> (AccessTokenEmail, SocialProfile?, LoginType) in
                            accessToken.googleToken = token
                            return (accessToken, profile, type)
                    })
            case .twitter(_): return .empty()
            case .apple(_): return .empty()
            }
        }
        .flatMap { [weak self] (token, type, loginType) -> Observable<(AccessTokenEmail, UserPrivate)> in
            return Observable<(AccessTokenEmail, UserPrivate)>
                .combineLatest(Observable<AccessTokenEmail>.just(token), self?.getPrivateInfo(with: token.token) ?? Observable.empty(), resultSelector: { (token, userPrivate) -> (AccessTokenEmail, UserPrivate) in
                if let profileSocial = type {
                    userPrivate.statusLogin = UserLoginStatus(rawValue: profileSocial.type.rawValue) ?? .email
                    let profile = userPrivate.socials.filter { $0.type == profileSocial.type }.first
                    if let social = profile {
                        social.id = profileSocial.id
                    } else {
                        userPrivate.socials.append(profileSocial)
                    }
                }
                switch loginType {
                case .email(let email, _):
                    userPrivate.profile?.email = email
                    break
                default:
                    break
                }
                token.id = userPrivate.id
                return (token, userPrivate)
            })
        }
        .do(onNext: { (accessToken, _) in
            Session.shared.accessToken = accessToken.token
        })
        .map { $0.1 }
//        .filter { (token, _) in !token.token.isEmpty }
//        .flatMapLatest {
//            Observable<UserPrivate>
//                .combineLatest(
//                    Repository<AccessTokenEmail, AccessTokenObject>.shared.save(object: $0),
//                    Observable<UserPrivate>.just($1),
//                    resultSelector: { (_, userPrivate) -> UserPrivate in
//                        return userPrivate
//                }
//            )
//        }
        .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
        .do(onNext: { (_) in
            FirebaseBackground.shared.registerFirebaseToken()
        })
            .subscribe(onNext: { [weak self] (_) in
                self?.view.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.performSegue(withIdentifier: Gat.Segue.openSetNewPasswordBySocial, sender: self?.emailLabel.text)
            }).disposed(by: self.disposeBag)
        
    }
    
    fileprivate func login(request: Observable<(String, SocialProfile?)>) -> Observable<(String, LoginType)> {
        return request
            .filter { $0.1 != nil }
            .flatMap { [weak self] (code, social) -> Observable<LoginType> in
                switch social!.type {
                case .facebook: return self?.loginFacebook() ?? .empty()
                case .google: return self?.loginGoogle() ?? .empty()
                default: return .empty()
                }
        }
        .flatMap({ [weak self] (type) -> Observable<(String, String?, UserType, LoginType)> in
            return Observable<(String, String?, UserType, LoginType)>
                .combineLatest(
                    UserNetworkService
                    .shared
                    .login(with: type, uuid: UIDevice.current.identifierForVendor?.uuidString ?? "")
                    .catchError({ [weak self] (error) -> Observable<(String, String?, UserType)> in
                        self?.view.isUserInteractionEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }),
                    Observable<LoginType>.just(type),
                    resultSelector: { (result, type) -> (String, String?, UserType, LoginType) in
                        return (result.0, result.1, result.2, type)
                    }
                )
        })
        .map { (token, _, _, type) in (token, type) }
    }
    
    fileprivate func loginFacebook() -> Observable<LoginType> {
        return FacebookService.shared.login()
            .catchError({ [weak self] (error) -> Observable<String> in
                self?.view.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return .empty()
            })
            .flatMap { [weak self] _ in
                FacebookService.shared.profile()
                    .catchError { [weak self] (error) -> Observable<SocialProfile> in
                        self?.view.isUserInteractionEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return .empty()
                }
        }
        .map { $0.id }
        .flatMapLatest { [weak self] value in
            Observable<LoginType>
                .just(.facebook(value))
                .catchError({ [weak self] (error) -> Observable<LoginType> in
                    HandleError.default.showAlert(with: error)
                    self?.view.isUserInteractionEnabled = true
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    return Observable.empty()
                })
        }
    }
    
    fileprivate func loginGoogle() -> Observable<LoginType> {
        return self.googleService.signIn(viewController: self)
            .withLatestFrom(Observable.just(self))
            .flatMap({ (vc) -> Observable<(SocialProfile, Error?)> in
                return .combineLatest(vc.googleService.profileObservable, vc.googleService.errorObservable, resultSelector: { ( $0, $1) })
            })
        .do(onNext: { [weak self] (_, error) in
            if let error = error {
                HandleError.default.showAlert(with: error)
                self?.view.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        })
            .filter { !$0.id.isEmpty && $1 == nil }
            .map { $0.0.id }
            .flatMapLatest { Observable<LoginType>.just(.google($0)) }
    }
    
    fileprivate func getPrivateInfo(with token: String) -> Observable<UserPrivate> {
        return UserNetworkService
            .shared
            .privateInfo(with: token)
            .catchError({ [weak self] (error) -> Observable<UserPrivate> in
                self?.view.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            })
    }
    
    //MARK: - UI
    private func setupUI() {
        self.titleLabel.text = Gat.Text.ForgotPassword.FORGOT_PASSWORD_TITLE.localized()
        self.emailLabel.attributedPlaceholder = .init(string: Gat.Text.ForgotPassword.EMAIL_ADDRESS_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.messageLabel.text = Gat.Text.ForgotPassword.MESSAGE_FORGOT.localized()
        self.messageLabel.sizeToFit()
        self.sendEmailLabel.text = Gat.Text.ForgotPassword.SEND_EMAIL_TITLE.localized()
        Observable<String>
            .combineLatest(self.email, self.isLockEmail, resultSelector: { $1 ? $0.secureEmail() : $0 })
            .bind(to: self.emailLabel.rx.text)
            .disposed(by: self.disposeBag)
        self.isLockEmail
            .map { !$0 }
            .subscribe(self.emailLabel.rx.isUserInteractionEnabled)
            .disposed(by: self.disposeBag)
        self.isLockEmail.map { !$0 }
            .subscribe(self.emailLabel.rx.isEnabled)
            .disposed(by: self.disposeBag)
        self.isLockEmail.subscribe(onNext: {print($0)}).disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.hideKeyboardWhenTappedAround()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @IBAction func Back(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.openConfirmPassword {
            let vc = segue.destination as! ConfirmForgotPasswordViewController
            self.emailLabel.rx.text.orEmpty.asObservable().subscribe(vc.senderEmail).disposed(by: self.disposeBag)
            vc.tokenResetPassword.onNext(sender as! String)
        } else if segue.identifier == Gat.Segue.openSetNewPasswordBySocial {
            let vc = segue.destination as! ResetPasswordFromSocialViewController
            vc.email.onNext(sender as! String)
        }
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
}

//MARK: - Extension
extension ForgotPasswordViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
