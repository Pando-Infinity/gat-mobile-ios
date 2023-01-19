//
//  ScanUserSuccessViewController.swift
//  gat
//
//  Created by macOS on 8/14/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ScanUserSuccessViewController: UIViewController {
    
    @IBOutlet weak var contentView:UIView!
    @IBOutlet weak var contentViewNumberBook:UIView!
    @IBOutlet weak var contentViewNumberFollow:UIView!
    @IBOutlet weak var imgUser:UIImageView!
    @IBOutlet weak var lbName:UILabel!
    @IBOutlet weak var lbUserName:UILabel!
    @IBOutlet weak var lbNumberBook:UILabel!
    @IBOutlet weak var lbNumberFollow:UILabel!
    @IBOutlet weak var lbNumberBookTitle:UILabel!
    @IBOutlet weak var lbNumberFollowTitle:UILabel!
    @IBOutlet weak var btnExit:UIButton!
    @IBOutlet weak var btnFollow:UIButton!
    @IBOutlet weak var btnGoToProfilePage:UIButton!
    
    let userPublic: BehaviorSubject<UserPublic> = .init(value: UserPublic())
    let isFollow: BehaviorSubject<Bool> = .init(value: false)
    
    fileprivate var numberFollowers = 0
    
    fileprivate let disposeBag = DisposeBag()
    
//    override func viewWillAppear(_ animated: Bool) {
//        self.getData()
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
        self.getData()
    }
    
//MARK: - UI
    func setupUI(){
        self.setupGradientBackground()
        self.cornerRadius()
        self.setupContentItem()
        self.setupFollowbtn()
        
        self.lbNumberBookTitle.text = "BOOK_IN_SHELVES".localized()
        self.lbNumberFollowTitle.text = "FOLLOW_IN_SCAN_USER".localized()
        self.btnGoToProfilePage.setTitle("GO_TO_PROFILE_PAGE".localized(), for: .normal)
        
        self.userPublic
            .bind{ [weak self] (user) in
               let profile = user.profile
                self?.imgUser.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId)), placeholderImage: DEFAULT_USER_ICON)
                self?.lbName.text = profile.name
                self?.lbUserName.text = profile.username
        }.disposed(by: self.disposeBag)
        
        self.userPublic.map { "\($0.sharingCount)" }.bind(to: self.lbNumberBook.rx.text).disposed(by: self.disposeBag)
        self.userPublic.map { " \($0.followingCount)" }.bind(to: self.lbNumberFollow.rx.text).disposed(by: self.disposeBag)
    }
    
    func btnFollowWhenFollowed(){
        self.btnFollow.setTitle(" " + "FOLLOWING_TITLE".localized(), for: .normal)
        self.btnFollow.setImage(UIImage(named: "buttonFollowed"), for: .normal)
        self.btnFollow.backgroundColor = .white
        self.btnFollow.setTitleColor(#colorLiteral(red: 0.2549019608, green: 0.5882352941, blue: 0.7607843137, alpha: 1), for: .normal)
        self.btnFollow.layer.borderColor = #colorLiteral(red: 0.2549019608, green: 0.5882352941, blue: 0.7607843137, alpha: 1).cgColor
        self.btnFollow.layer.borderWidth = 1.0
    }
    
    func btnFollowWhenNotFollow(){
        self.btnFollow.setTitle(" " + "FOLLOW_TITLE".localized(), for: .normal)
        self.btnFollow.setImage(UIImage(named: "buttonTextCopy"), for: .normal)
        self.btnFollow.backgroundColor = #colorLiteral(red: 0.2549019608, green: 0.5882352941, blue: 0.7607843137, alpha: 1)
        self.btnFollow.setTitleColor(.white, for: .normal)
        self.btnFollow.layer.borderColor = UIColor.clear.cgColor
        self.btnFollow.layer.borderWidth = 0.0
    }
    
    func setupFollowbtn(){
        self.userPublic.map { $0.followedByMe }.filter { !$0 }.subscribe(onNext: { [weak self] (_) in
            self?.btnFollowWhenNotFollow()
        }).disposed(by: self.disposeBag)
        
        self.userPublic.map { $0.followedByMe }.filter { $0 }.subscribe(onNext: { [weak self] (_) in
            self?.btnFollowWhenFollowed()
        }).disposed(by: self.disposeBag)
        
        self.userPublic.map { $0.followedByMe }.subscribe(self.isFollow).disposed(by: self.disposeBag)
        
        self.isFollow.subscribe(onNext: { (status) in
            status ? self.btnFollowWhenFollowed() : self.btnFollowWhenNotFollow()
        }).disposed(by: self.disposeBag)
        
        self.userPublic.map { $0.profile.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id }.bind(to: self.btnFollow.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    func setupGradientBackground(){
        let color = ColorsGradientUserScan()
        self.view.backgroundColor = UIColor.clear
        let backgroundLayer = color.gl
        backgroundLayer.frame = self.view.frame
        self.view.layer.insertSublayer(backgroundLayer, at: 0)
    }
    
    func cornerRadius(){
        self.imgUser.cornerRadius = self.imgUser.bounds.width / 2
        self.contentView.cornerRadius = 13.0
        self.btnFollow.cornerRadius = 9.0
    }
    
    func setupContentItem(){
        self.contentViewNumberBook.backgroundColor = .clear
        self.contentViewNumberBook.borderWidth = 1.0
        self.contentViewNumberBook.borderColor = UIColor.init(red: 225.0/255.0, green: 229.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        
        self.contentViewNumberFollow.backgroundColor = .clear
        self.contentViewNumberFollow.borderWidth = 1.0
        self.contentViewNumberFollow.borderColor = UIColor.init(red: 225.0/255.0, green: 229.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    }
  
    
//MARK: - EVENT
    func event(){
        self.btnExitEvent()
        self.btnGotoProfilePageEvent()
        self.followEvent()
    }
    
    func btnExitEvent(){
        self.btnExit
            .rx
            .controlEvent(.touchUpInside)
            .bind{ [weak self] (_) in
                UIApplication.topViewController()?.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
    }
    
    func btnGotoProfilePageEvent(){
        self.btnGoToProfilePage
            .rx
            .controlEvent(.touchUpInside)
            .bind{ [weak self] (_) in
                if try! self!.userPublic.value().profile.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                    let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                    vc.isShowButton.onNext(true)
                    vc.isShowEditButton.onNext(false)
                    UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let storyboard = UIStoryboard(name: "VistorProfile", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: UserVistorViewController.className) as! UserVistorViewController
                    vc.userPublic.onNext(try! self!.userPublic.value())
                    UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                }
        }.disposed(by: disposeBag)
    }
    
    fileprivate func showAlertUnfollow(user: UserPublic) {
        let unfollow = ActionButton(titleLabel: Gat.Text.UNFOLLOW_TITLE.localized()) { [weak self] in
            self?.unfollow(user: user)
        }
        let cancel = ActionButton(titleLabel: Gat.Text.CommonError.CANCEL_ERROR_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: String(format: Gat.Text.UNFOLLOW_ALERT_TITLE.localized(), user.profile.name), message: String(format: Gat.Text.UNFOLLOW_MESSAGE.localized(), user.profile.name), actions: [cancel, unfollow], in: self)
    }
    
    fileprivate func unfollow(user: UserPublic) {
        UserFollowService.shared
            .unfollow(userId: user.profile.id)
            .catchError({ (error) -> Observable<()> in
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            })
            .do(onNext: { [weak self] (_) in
                self?.numberFollowers -= 1
                self?.lbNumberFollow.text = "\(self?.numberFollowers ?? 0)"
            })
            .map { _ in false }
            .subscribe(onNext: { [weak self] (status) in
                guard let value = try? self?.userPublic.value(), let user = value else { return }
                user.followedByMe = status
                self?.userPublic.onNext(user)
            })
            .disposed(by: self.disposeBag)

    }

    
    fileprivate func followEvent() {
        let isFollow =  self.btnFollow.rx.tap.asObservable()
            .withLatestFrom(Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first })
            .do(onNext: { (userPrivate) in
                if userPrivate == nil {
                    HandleError.default.loginAlert()
                }
            })
            .filter { $0 != nil }
            .withLatestFrom(self.isFollow).share()
        
        isFollow
            .filter { $0 }
            .withLatestFrom(self.userPublic)
            .subscribe(onNext: { [weak self] (user) in
                self?.showAlertUnfollow(user: user)
            })
            .disposed(by: self.disposeBag)
        
        isFollow
            .filter { !$0 }
            .withLatestFrom(self.userPublic)
            .flatMap { (user) -> Observable<()> in
                return UserFollowService.shared
                    .follow(userId: user.profile.id)
                    .catchError({  (error) -> Observable<()> in
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
            .do(onNext: { [weak self] (_) in
                self?.numberFollowers += 1
                self?.lbNumberFollow.text = "\(self?.numberFollowers ?? 0)"
            })
            .map { _ in true }
            .subscribe(onNext: { [weak self] (status) in
                guard let value = try? self?.userPublic.value(), let user = value else { return }
                user.followedByMe = status
                self?.userPublic.onNext(user)
            })
            .disposed(by: self.disposeBag)
    }
    
//MARK: - DATA
    private func getData(){
        self.getUser()
    }
    fileprivate func getUser() {
        guard let value = try? self.userPublic.value() else { return }
        UserNetworkService.shared.publicInfoByUserName(user: value.profile)
            .catchError { (error) -> Observable<UserPublic> in
                
                HandleError.default.showAlert(with: error) {
                    self.navigationController?.popViewController(animated: true)
                }
                return Observable.empty()
            }
        .subscribe(self.userPublic)
        .disposed(by: self.disposeBag)
    }

}
