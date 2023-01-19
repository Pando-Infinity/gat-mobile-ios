//
//  UserVistorViewController.swift
//  gat
//
//  Created by Vũ Kiên on 27/02/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UserVistorViewController: UIViewController {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var vistorUserProfile: VistorUserProfileView!
    @IBOutlet weak var vistorUserTabView: VistorUserTabView!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var profileTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel:UILabel!
    @IBOutlet weak var tabTopConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var controllers: [UIViewController] = []
    var previousController: UIViewController?
    let userPublic: BehaviorSubject<UserPublic> = .init(value: UserPublic())
    let isFollow: BehaviorSubject<Bool> = .init(value: false)
    fileprivate let disposeBag = DisposeBag()
    fileprivate var groupMessage: Observable<GroupMessage?>!
    fileprivate var numberFollowers = 0
    fileprivate var numberFollowings = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setuUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getData()
        self.getTotalFollows()
        self.getTotalFollowers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.backgroundView.layer.sublayers?.removeAll(where: { $0.isKind(of: CAGradientLayer.self)})
        self.backgroundView.applyGradient(colors: GRADIENT_BACKGROUND_COLORS)
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.getUser()
    }
    
    fileprivate func getUser() {
        Observable<(UserPublic, Bool)>
            .combineLatest(self.userPublic.filter { $0.profile.id != 0 }.elementAt(0), Status.reachable.asObservable(), resultSelector: { ($0, $1) })
            .filter { (_, status) in status }
            .map { (userPublic, _) in userPublic }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest {
                UserNetworkService
                    .shared
                    .publicInfo(user: $0.profile)
                    .catchError { (error) -> Observable<UserPublic> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .subscribe(self.userPublic)
            .disposed(by: self.disposeBag)
    }
    
    func getTotalFollowers() {
        self.userPublic.map { $0.profile.id }.flatMap { UserFollowService.shared.totalFollowers(of: $0).catchErrorJustReturn(0)}
        .do(onNext: { [weak self] (total) in
            self?.numberFollowers = total
        }).map { "\($0)" }.bind(to: self.vistorUserProfile.totalFollowersLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    func getTotalFollows() {
        self.userPublic.map { $0.profile.id }.flatMap { UserFollowService.shared.totalFollows(of: $0).catchErrorJustReturn(0)}.do(onNext: { [weak self] (total) in
            self?.numberFollowings = total
        }).map { "\($0)" }.bind(to: self.vistorUserProfile.totalFollowingsLabel.rx.text).disposed(by: self.disposeBag)
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
                self?.vistorUserProfile.totalFollowersLabel.text = "\(self?.numberFollowers ?? 0)"
            })
            .map { _ in false }
            .subscribe(onNext: { [weak self] (status) in
                guard let value = try? self?.userPublic.value(), let user = value else { return }
                user.followedByMe = status
                self?.userPublic.onNext(user)
            })
            .disposed(by: self.disposeBag)

    }
    
    //MARK: - UI
    fileprivate func setuUI() {
        self.view.layoutIfNeeded()
        self.vistorUserTabView.controller = self
        self.setupMessageButton()
        self.backgroundImageView.isHidden = true
        self.setupProfileView()
        self.isFollow.subscribe(onNext: { [weak self] (status) in
            self?.vistorUserProfile.followButton.setTitle(status ? "FOLLOWING_TITLE".localized() : Gat.Text.FOLLOW_TITLE.localized(), for: .normal)
        })
        .disposed(by: self.disposeBag)
        self.userPublic.map { $0.followedByMe }.subscribe(self.isFollow).disposed(by: self.disposeBag)
        self.performSegue(withIdentifier: "showSharingBooksUserVistor", sender: nil)
    }
    
    fileprivate func setupMessageButton() {
        self.messageButton.isHidden = !Session.shared.isAuthenticated
        self.messageButton.isUserInteractionEnabled = false
    }
    
    fileprivate func setupProfileView() {
        self.userPublic
            .subscribe(onNext: { [weak self] (userPublic) in
//                self?.setupAbout(userPublic.profile.about)
                self?.nameLabel.text = userPublic.profile.name
                self?.usernameLabel.text = userPublic.profile.username
                self?.vistorUserProfile.controller = self
                self?.vistorUserProfile.setup(profile: userPublic.profile)
                self?.messageButton.isUserInteractionEnabled = true
                self?.vistorUserTabView.isUserInteractionEnabled = true
                self?.vistorUserTabView.configureBookSharing(total: userPublic.sharingCount)
                self?.vistorUserTabView.configureReviewBook(total: userPublic.articleCount)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showAlertUnfollow(user: UserPublic) {
        let unfollow = ActionButton(titleLabel: Gat.Text.UNFOLLOW_TITLE.localized()) { [weak self] in
            self?.unfollow(user: user)
        }
        let cancel = ActionButton(titleLabel: Gat.Text.CommonError.CANCEL_ERROR_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: String(format: Gat.Text.UNFOLLOW_ALERT_TITLE.localized(), user.profile.name), message: String(format: Gat.Text.UNFOLLOW_MESSAGE.localized(), user.profile.name), actions: [unfollow, cancel], in: self)
    }
    
    fileprivate func showMessage(groupId: String) {
        guard let user = try? self.userPublic.value() else { return }
        let storyboard = UIStoryboard(name: Gat.Storyboard.Message, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: Gat.View.MessageViewController) as! MessageViewController
        if let group = Repository<GroupMessage, GroupMessageObject>.shared.get(predicateFormat: "groupId = %@", args: [groupId]) {
            vc.group.onNext(group)
        } else {
            let group = GroupMessage()
            group.groupId = groupId
            group.users.append(user.profile)
            vc.group.onNext(group)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    //MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backButtonEvent()
        self.messageEvent()
        self.followEvent()
    }
    
    fileprivate func messageEvent() {
        self.messageButton.rx.tap
            .do(onNext: { (_) in
                if !Session.shared.isAuthenticated {
                    HandleError.default.loginAlert()
                }
            })
            .filter { Session.shared.isAuthenticated }
            .flatMap { [weak self] (_) -> Observable<String> in
                guard let value = try? self?.userPublic.value(), let userPublic = value, let userPrivate = Session.shared.user else {
                    return Observable.empty()
                }
                let groupId = userPrivate.id > userPublic.profile.id ? "\(userPublic.profile.id):\(userPrivate.id)" : "\(userPrivate.id):\(userPublic.profile.id)"
                return Observable<String>.just(groupId)
            }
            .subscribe(onNext: { [weak self] (groupId) in
                self?.showMessage(groupId: groupId)
            })
            .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func backButtonEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func followEvent() {
        let isFollow =  self.vistorUserProfile.followButton.rx.tap.asObservable()
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
                self?.vistorUserProfile.totalFollowersLabel.text = "\(self?.numberFollowers ?? 0)"
            })
            .map { _ in true }
            .subscribe(onNext: { [weak self] (status) in
                guard let value = try? self?.userPublic.value(), let user = value else { return }
                user.followedByMe = status
                self?.userPublic.onNext(user)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSharingBooksUserVistor" {
            let vc = segue.destination as? SharingBookContainerController
            vc?.userVistorController = self
        } else if segue.identifier == "showReviewBooksUserVistor" {
            let vc = segue.destination as? ListReviewVistorUserViewController
            vc?.userVistorController = self
        } else if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == "showVisitorPost" {
            let vc = segue.destination as? VisitorArticleVC
            vc?.userVistorController = self
            if let user = try? self.userPublic.value() {
                vc?.idUser.onNext(user.profile.id)
            }
        } else if segue.identifier == Gat.Segue.SHOW_REQUEST_DETAIL_BORROWER_INDETIFIER {
            let vc = segue.destination as? RequestDetailBorrowerViewController
            vc?.userSharingBook.onNext(sender as! UserSharingBook)
        } else if segue.identifier == Gat.Segue.SHOW_REQUEST_DETAIL_S_IDENTIFIER {
            let vc = segue.destination as? RequestBorrowerViewController
            vc?.bookRequest.onNext(sender as! BookRequest)
        } else if segue.identifier == FollowViewController.segueIdentifier {
            let vc = segue.destination as? FollowViewController
            if let user = try? self.userPublic.value() {
                vc?.user.onNext(user.profile)
                vc?.numberFollowers.onNext(self.numberFollowers)
                vc?.numberFollowings.onNext(self.numberFollowings)
                vc?.type.onNext(sender as! FollowViewController.FollowType)
            }
        }
    }
}

extension UserVistorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
