//
//  ProfileViewController.swift
//  gat
//
//  Created by Vũ Kiên on 08/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON
import RealmSwift

class ProfileViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var profileDetailView: ProfileDetailView!
    @IBOutlet weak var containerTabView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet var profileTabView: ProfileTabView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel:UILabel!
    @IBOutlet weak var seperateView: UIView!
    @IBOutlet weak var editButton:UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var controllers: [UIViewController] = []
    var previousController: UIViewController?
    
    let isShowButton: BehaviorSubject<Bool> = .init(value: false)
    let isShowEditButton: BehaviorSubject<Bool> = .init(value: true)
    
    let userPrivate = BehaviorSubject<UserPrivate>(value: UserPrivate())
    fileprivate let disposeBag = DisposeBag()
    fileprivate var numberFollowers = 0
    fileprivate var numberFollowings = 0

    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        if Session.shared.isAuthenticated {
            if let user = Session.shared.user {
                self.userPrivate.onNext(user)
            }
            self.getUserInfo()
        }
        self.setup()
        self.event()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Session.shared.isAuthenticated {
            self.getUserLocal()
            self.getTotalFollowers()
            self.getTotalFollows()
            self.profileTabView.getData()
        } else {
            HandleError.default.loginAlert(action: { [weak self] in
                self?.tabBarController?.selectedViewController = self?.tabBarController?.viewControllers?.first
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.backgroundView.layer.sublayers?.removeAll(where: {$0.isKind(of: CAGradientLayer.self)})
        self.setupBackgroundGradient()
    }
    
    //MARK: - Setup
    fileprivate func setup() {
        self.setupProfileDetail()
        self.setupBackButton()
        self.setupTabView()
        self.setupEditButton()
        self.performSegue(withIdentifier: "showSharingBook", sender: nil)
    }
    
    fileprivate func setupProfileDetail() {
        self.view.layoutIfNeeded()
        self.profileDetailView.controller = self
        self.profileDetailView.setupUI()
    }
    
    fileprivate func setupBackButton() {
        self.isShowButton
            .map { !$0 }
            .subscribe(self.backButton.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupEditButton() {
        self.isShowEditButton
            .map{ !$0 }
            .subscribe(self.editButton.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    func setupBackgroundGradient() {
        self.backgroundView.applyGradient(colors: GRADIENT_BACKGROUND_COLORS)
    }
    
    fileprivate func setupTabView() {
        self.view.layoutIfNeeded()
        self.profileTabView.frame = self.containerTabView.bounds
        self.profileTabView.controller = self
        self.containerTabView.addSubview(self.profileTabView)
        
        self.userPrivate
            .bind { [weak self] (user) in
                self?.usernameLabel.text = user.profile?.username
                self?.nameLabel.text = user.profile?.name
                self?.profileTabView.configureSharingBook(number: user.instanceCount)
                self?.profileTabView.configureBorrowingRequest(number: user.requestCount)
                self?.profileTabView.configureReviewBook(number: user.articleCount)
            }
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Data
    func saveUser(instanceCount: Int? = nil, articleCount: Int? = nil, requestCount: Int? = nil) {
        self.userPrivate
            .do(onNext: { (user) in
                if let count = instanceCount {
                    user.instanceCount = count
                }
                if let count = articleCount {
                    user.articleCount = count
                }
                if let count = requestCount {
                    user.requestCount = count
                }
            })
            .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getUserLocal() {
        Repository<UserPrivate, UserPrivateObject>.shared
            .getAll()
            .map { $0.first }
            .filter { $0 != nil }
            .map { $0! }
            .subscribe(onNext: { [weak self] (userPrivate) in
                self?.userPrivate.onNext(userPrivate)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getUserInfo() {
        Status
            .reachable
            .asObservable()
            .filter { $0 }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest { _ in
                UserNetworkService
                    .shared
                    .privateInfo()
                    .catchError({ (error) -> Observable<UserPrivate> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
            .do(onNext: { [weak self] (user) in
                self?.userPrivate.onNext(user)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .flatMap {
                Observable<UserPrivate>
                    .combineLatest(
                        Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                        Observable<UserPrivate>.just($0),
                        resultSelector: { (old, new) -> UserPrivate in
                            old.update(new: new)
                            return old
                    })
                
            }
            .flatMapLatest { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    func getTotalFollowers() {
        UserFollowService.shared.totalFollowers().catchErrorJustReturn(0).do(onNext: { [weak self] (total) in
            self?.numberFollowers = total
        }).map { "\($0)" }.bind(to: self.profileDetailView.totalFollowersLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    func getTotalFollows() {
        UserFollowService.shared.totalFollows().catchErrorJustReturn(0).do(onNext: { [weak self] (total) in
            self?.numberFollowings = total
        }).map { "\($0)" }.bind(to: self.profileDetailView.totalFollowingsLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    //MARK: - UI    
    func changeFrame(scrollView: UIScrollView) {
//        guard scrollView.contentOffset.y > 0 && self.backgroundView.frame.height - scrollView.contentOffset.y >= self.headerView.frame.height else {
//            if scrollView.contentOffset.y <= 0 {
//                self.headerView.layer.sublayers?.removeAll(where: {$0.isKind(of: CAGradientLayer.self)})
//            }
//            return
//        }
//        if self.headerView.layer.sublayers?.filter ({ $0.isKind(of: CAGradientLayer.self)}).first == nil {
//            self.headerView.applyGradient(colors: GRADIENT_BACKGROUND_COLORS)
//        }
//        self.backgroundView.frame.origin.y = -scrollView.contentOffset.y
//        self.profileDetailView.frame.origin.y = self.headerView.frame.height - scrollView.contentOffset.y
//        self.containerTabView.frame.origin.y = self.backgroundView.frame.origin.y + self.backgroundView.frame.height
//        self.seperateView.frame.origin.y = self.containerTabView.frame.origin.y + self.containerTabView.frame.height
//        self.containerView.frame.origin.y = self.seperateView.frame.origin.y + self.seperateView.frame.height
//        self.containerView.frame.size.height = self.view.frame.height - self.containerView.frame.origin.y
    }
    
    func showAlert(title: String = Gat.Text.UserProfile.ERROR_ALERT_TITLE.localized(), message: String, actions: [ActionButton]) {
        AlertCustomViewController.showAlert(title: title, message: message, actions: actions, in: self)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.backButtonEvent()
        self.editButtonEvent()
    }
    
    func editButtonEvent(){
        self.editButton
        .rx
            .controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.showAlertEdit()
            }
            .disposed(by: self.disposeBag)
    }
    
    func showAlertEdit(){
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let showQRcodeProfileAction = UIAlertAction(title: "SHARE_PROFILE".localized(), style: .default) { [weak self] (action) in
            self?.performSegue(withIdentifier: "showScanUserProfile", sender: nil)
        }
        let cancelAction = UIAlertAction(title: Gat.Text.BookDetail.CANCEL_ALERT_TITLE.localized(), style: .cancel)
        alert.addAction(showQRcodeProfileAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func backButtonEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                if self?.navigationController?.presentingViewController?.presentedViewController == self?.navigationController {
                    if self?.navigationController?.viewControllers.count == 1 {
                        self?.dismiss(animated: true, completion: nil)
                    } else {
                        self?.navigationController?.popViewController(animated: true)
                    }
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSharingBook" {
            let toVC = segue.destination as? SharingBookContainer
            toVC?.profileViewController = self
        } else if segue.identifier == "showBorrowingRequest" {
            let toVC = segue.destination as? BorrowingRequestContainer
            toVC?.profileViewController = self
        } else if segue.identifier == "showReviewBooks" {
            let toVC = segue.destination as? ListUserEvaluationViewController
            toVC?.profileViewController = self
        }else if segue.identifier == "showPersonalPost" {
            let toVC = segue.destination as? UserArticleVC
            toVC?.profileViewController = self
        }else if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.hidesBottomBarWhenPushed = true
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == Gat.Segue.openVisitorPage {
            let vc = segue.destination as? UserVistorViewController
            vc?.hidesBottomBarWhenPushed = true
            vc?.userPublic.onNext(sender as! UserPublic)
        } else if segue.identifier == Gat.Segue.SHOW_REQUEST_DETAIL_O_IDENTIFIER {
            let vc = segue.destination as? RequestOwnerViewController
            vc?.hidesBottomBarWhenPushed = true
            vc?.bookRequest.onNext(sender as! BookRequest)
        } else if segue.identifier == Gat.Segue.SHOW_REQUEST_DETAIL_S_IDENTIFIER {
            let vc = segue.destination as? RequestBorrowerViewController
            vc?.hidesBottomBarWhenPushed = true
            vc?.bookRequest.onNext(sender as! BookRequest)
        } else if segue.identifier == "showRequestDetailBookstopOrganization" {
            let vc = segue.destination as? RequestBorrowerBookstopOrganizationViewController
            vc?.hidesBottomBarWhenPushed = true 
            vc?.bookRequest.onNext(sender as! BookRequest)
        } else if segue.identifier == FollowViewController.segueIdentifier {
            let vc = segue.destination as? FollowViewController
            if let user = try? self.userPrivate.value() {
                vc?.user.onNext(user.profile ?? Profile())
                vc?.numberFollowers.onNext(self.numberFollowers)
                vc?.numberFollowings.onNext(self.numberFollowings)
                vc?.type.onNext(sender as! FollowViewController.FollowType)
            }
        } else if segue.identifier == BookstopOriganizationViewController.segueIdentifier {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        } else if segue.identifier == "showScanUserProfile" {
            let vc = segue.destination as? ScanUserViewController
            vc?.hidesBottomBarWhenPushed = true
        }
    }
}
