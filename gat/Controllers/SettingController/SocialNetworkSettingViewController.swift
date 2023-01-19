//
//  SocialNetworkSettingViewController.swift
//  gat
//
//  Created by HungTran on 5/6/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift
import RxCocoa
import Firebase

class SocialNetworkSettingViewController: UIViewController {
    //MARK: - UI Properties
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var cancelConnectButton: UIButton!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var socialInformationTitle: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    let socialProfile: BehaviorSubject<SocialProfile> = .init(value: SocialProfile())

    private var disposeBag = DisposeBag()
   
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupEvent()
        self.setupUI()
    }
    
    //MARK: - Event
    private func setupEvent() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.setupUnlinkEvent()
        self.setupBackButtonEvent()
    }
    
    private func setupUnlinkEvent() {        
        self.getSocialProfile()
            .map { $0.type }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.cancelConnectButton.isUserInteractionEnabled = false
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap { [weak self] (type) in
                UserNetworkService
                    .shared
                    .unlink(social: type)
                    .catchError { [weak self] (error) -> Observable<()> in
                        self?.cancelConnectButton.isUserInteractionEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .withLatestFrom(self.socialProfile)
            .flatMap { (social) -> Observable<()> in
                social.statusLink = false
                return Repository<SocialProfile, SocialProfileObject>.shared.save(object: social)
                    .do(onNext: { (_) in
                        print("STATUS LINK: \(social.statusLink)")
                        
                    })
            }
            .subscribe(onNext: { [weak self] _ in
                self?.cancelConnectButton.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getSocialProfile() -> Observable<SocialProfile> {
        return self.cancelConnectButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(Repository<UserPrivate, UserPrivateObject>.shared.getFirst())
            .do(onNext: { (userPrivate) in
                if !userPrivate.passwordFlag {
                    // alert
                }
            })
            .filter { $0.passwordFlag }
            .withLatestFrom(self.socialProfile)
    }
    
    private func setupBackButtonEvent() {
        self.backButton
            .rx
            .tap
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }

    
    //MARK: - UI
    private func setupUI() {
        self.cancelConnectButton.setTitle(Gat.Text.SocialNetwork.DISCONNECT_TITLE.localized(), for: .normal)
        self.setupTitleTextUI()
    }
    
    /**Kích hoạt tương tác các nút trong giao diện*/
    private func enableStatus(_ status: Bool) {
        self.cancelConnectButton.isUserInteractionEnabled = status
    }
    
    private func setupTitleTextUI() {
        self.socialProfile
            .map { (profile) -> String in
                var title = ""
                switch profile.type {
                case .facebook:
                   title = Gat.Text.SocialNetwork.FACEBOOK_TITLE
                    break
                case .google:
                    title = Gat.Text.SocialNetwork.GOOGLE_TITLE
                    break
                case .twitter:
                    title = Gat.Text.SocialNetwork.TWITTER_TITLE
                    break
                case .apple: break
                }
                return String(format: Gat.Text.SocialNetwork.CONNECTING_ACCOUNT_TITLE.localized(), title, profile.name)
            }
            .subscribe(self.socialInformationTitle.rx.text)
            .disposed(by: self.disposeBag)
        
        self.socialProfile
            .map { (profile) -> String in
                switch profile.type {
                case .facebook:
                    return Gat.Text.SocialNetwork.FACEBOOK_TITLE
                case .google:
                    return Gat.Text.SocialNetwork.GOOGLE_TITLE
                case .twitter:
                    return Gat.Text.SocialNetwork.TWITTER_TITLE
                case .apple: return ""
                }
            }
            .map { $0.uppercased() }
            .subscribe(self.viewTitle.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
}

//MARK: - Extension
extension SocialNetworkSettingViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
