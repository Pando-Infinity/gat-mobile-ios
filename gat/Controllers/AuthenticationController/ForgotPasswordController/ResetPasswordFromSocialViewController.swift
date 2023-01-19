//
//  ResetPasswordFromSocialViewController.swift
//  gat
//
//  Created by HungTran on 5/23/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift
import FirebaseAnalytics

class ResetPasswordFromSocialViewController: UIViewController {
    
    //MARK: - UI Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var changePassLabel: UILabel!
    
    //MARK: - Public Data Properties
    let email: BehaviorSubject<String> = .init(value: "")
    
    //MARK: - Private Data Properties
    private var disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.request()
        self.setupUI()
    }
    
    // MARK: - Send Request
    fileprivate func request() {
        self.saveButton
            .rx
            .tap
            .asObservable()
            .map { [weak self] (_) -> String in
                return self?.newPassword.text ?? ""
            }
            .filter { !$0.isEmpty }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.view.isUserInteractionEnabled = false
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap { [weak self] (newPassword) in
                UserNetworkService
                    .shared
                    .update(newPassword: newPassword, currentPassword: "", uuid: UIDevice.current.identifierForVendor?.uuidString ?? "")
                    .catchError({ [weak self] (error) -> Observable<(String, String?)> in
                        self?.view.isUserInteractionEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
        .map { $0.0 }
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
            .do(onNext: { (user) in
                user.passwordFlag = true
            })
        })
        .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
        .do(onNext: { (_) in
            MessageService.shared.configure()
        })
            .subscribe(onNext: { [weak self] (_) in
                self?.view.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                FirebaseBackground.shared.registerFirebaseToken()
                self?.goToHome()
            })
            .disposed(by: self.disposeBag)
        
    }
    
    //MARK: - UI
    private func setupUI() {
        // Do any additional setup after loading the view.
        self.titleLabel.text = Gat.Text.ResetPasswordForSocial.FORGOT_PASSWORD_TITLE.localized()
        self.newPassword.attributedPlaceholder = .init(string: Gat.Text.ResetPasswordForSocial.NEW_PASSWORD_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.changePassLabel.text = Gat.Text.ResetPasswordForSocial.CHANGE_PASSWORD_TITLE.localized()
        self.messageLabel.text = Gat.Text.ResetPasswordForSocial.MESSAGE_FORGOT.localized()
        self.email.bind(to: self.userEmail.rx.text).disposed(by: self.disposeBag)
    }
    
    fileprivate func goToHome() {
        let storyboard = UIStoryboard.init(name: Gat.Storyboard.Main, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "TabBarController")
        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = vc
    }
}
