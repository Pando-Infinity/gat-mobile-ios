import UIKit
import RxSwift

class FollowViewController: UIViewController {
    
    class var segueIdentifier: String { return "showFollow" }
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingsLabel: UILabel!
    @IBOutlet weak var segmentLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var followersView: UIView!
    @IBOutlet weak var followingsView: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let user: BehaviorSubject<Profile> = .init(value: Profile())
    let numberFollowers: BehaviorSubject<Int> = .init(value: 0)
    let numberFollowings: BehaviorSubject<Int> = .init(value: 0)
    let type: BehaviorSubject<FollowType> = .init(value: .follower)
    
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var statusShow: SearchState = .new
    fileprivate let users: BehaviorSubject<[UserPublic]> = .init(value: [])
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getNumberFollow()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        let observables = Observable
            .combineLatest(self.user, self.page, self.type, resultSelector: {($0, $1, $2)})
            .filter { _ in Status.reachable.value }
        let followers = observables.filter { $0.2 == .follower }
            .map { ($0.0, $0.1) }
            .flatMap { (profile, page) -> Observable<[UserPublic]> in
                if profile.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                    return UserFollowService.shared
                        .followers(page: page)
                        .catchError({ (error) -> Observable<[UserPublic]> in
                            HandleError.default.showAlert(with: error)
                            return Observable.empty()
                        })
                } else {
                    return UserFollowService.shared
                        .followers(of: profile.id, page: page)
                        .catchError({ (error) -> Observable<[UserPublic]> in
                            HandleError.default.showAlert(with: error)
                            return Observable.empty()
                        })
                }
            }
        let followings = observables.filter { $0.2 == .following }
            .map { ($0.0, $0.1) }
            .flatMap { (profile, page) -> Observable<[UserPublic]> in
                if profile.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                    return UserFollowService.shared
                        .follows(page: page)
                        .catchError({ (error) -> Observable<[UserPublic]> in
                            HandleError.default.showAlert(with: error)
                            return Observable.empty()
                        })
                } else {
                    return UserFollowService.shared
                        .follows(of: profile.id, page: page)
                        .catchError({ (error) -> Observable<[UserPublic]> in
                            HandleError.default.showAlert(with: error)
                            return Observable.empty()
                        })
                }
            }
        
        Observable.of(followers, followings).merge()
            .subscribe(onNext: { [weak self] (users) in
                guard let status = self?.statusShow, let value = try? self?.users.value(), var list = value else { return }
                switch status {
                case .new:
                    list = users
                    break
                case .more:
                    list.append(contentsOf: users)
                    break
                }
                self?.users.onNext(list)
            })
            .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func getNumberFollow() {
        let `private` = self.user.filter { $0.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id }
        `private`.flatMap { _ in UserFollowService.shared.totalFollowers().catchErrorJustReturn(0) }.subscribe(self.numberFollowers).disposed(by: self.disposeBag)
        `private`.flatMap { _ in UserFollowService.shared.totalFollows().catchErrorJustReturn(0) }.subscribe(self.numberFollowings).disposed(by: self.disposeBag)
        let `public` = self.user.filter { $0.id != Repository<UserPrivate, UserPrivateObject>.shared.get()?.id }
        `public`.flatMap { UserFollowService.shared.totalFollowers(of: $0.id).catchErrorJustReturn(0) }.subscribe(self.numberFollowers).disposed(by: self.disposeBag)
        `public`.flatMap { UserFollowService.shared.totalFollows(of: $0.id).catchErrorJustReturn(0) }.subscribe(self.numberFollowings).disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.view.layoutIfNeeded()
        self.userImageView.circleCorner()
        self.setupUser()
        self.headerView.applyGradient(colors: GRADIENT_BACKGROUND_COLORS)
        self.setupCollectionView()
        self.setupTab()
    }
    
    fileprivate func setupCollectionView() {
        self.users.bind(to: self.collectionView.rx.items(cellIdentifier: UserFollowCollectionViewCell.identifier, cellType: UserFollowCollectionViewCell.self)) { [weak self] (index, user, cell) in
            cell.user.onNext(user)
            cell.removeUser = self?.remove(user:)
            cell.addUser = self?.add(user:)
            if let value = try? self?.user.value(), let type = try? self?.type.value(), let t = type {
                cell.currentUser = value
                cell.type.onNext(t)
            }
            }.disposed(by: self.disposeBag)
        self.collectionView.delegate = self
    }
    
    fileprivate func setupUser() {
        self.user.map { $0.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.user.map { AppConfig.sharedConfig.setUrlImage(id: $0.imageId) }.map { URL(string: $0) }.subscribe(onNext: { [weak self] (url) in
            self?.userImageView.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "default_user_avatar"))
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTab() {
        self.numberFollowers.map { "\($0) \(Gat.Text.FOLLOWERS_TITLE.localized())" }.bind(to: self.followersLabel.rx.text).disposed(by: self.disposeBag)
        self.numberFollowings.map { "\($0) \(Gat.Text.FOLLOWINGS_TITLE.localized())" }.bind(to: self.followingsLabel.rx.text).disposed(by: self.disposeBag)
        self.type.filter { $0 == .follower}.subscribe(onNext: { [weak self] (_) in
            self?.view.layoutIfNeeded()
            self?.followersLabel.textColor = #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 1)
            self?.followersLabel.font = .systemFont(ofSize: 15.0, weight: .bold)
            self?.followingsLabel.textColor = #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 0.5)
            self?.followingsLabel.font = .systemFont(ofSize: 15.0, weight: .regular)
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.segmentLeadingConstraint.constant = 0.0
                self?.view.layoutIfNeeded()
            })
        }).disposed(by: self.disposeBag)
        self.type.filter { $0 == .following}.subscribe(onNext: { [weak self] (_) in
            self?.view.layoutIfNeeded()
            self?.followingsLabel.textColor = #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 1)
            self?.followingsLabel.font = .systemFont(ofSize: 15.0, weight: .bold)
            self?.followersLabel.textColor = #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 0.5)
            self?.followersLabel.font = .systemFont(ofSize: 15.0, weight: .regular)
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.segmentLeadingConstraint.constant = (self?.view.frame.width ?? 0.0) / 2.0
                self?.view.layoutIfNeeded()
            })
        }).disposed(by: self.disposeBag)
    }
    
    // MARL: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
        self.tabEvent()
        self.collectionViewEvent()
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(UserPublic.self).subscribe(onNext: { [weak self] (user) in
            if user.profile.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                vc.isShowButton.onNext(true)
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
            } else {
                self?.performSegue(withIdentifier: Gat.Segue.openVisitorPage, sender: user)
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func tabEvent() {
        self.followersView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.statusShow = .new
            self?.type.onNext(.follower)
            self?.page.onNext(1)
            
        })
        .disposed(by: self.disposeBag)
        
        self.followingsView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.statusShow = .new
            self?.type.onNext(.following)
            self?.page.onNext(1)
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func remove(user: UserPublic) {
        guard var users = try? self.users.value(), let count = try? self.numberFollowings.value(), let type = try? self.type.value() else { return }
        if type == .following {
            users.removeAll(where: {$0.profile.id == user.profile.id })
            self.users.onNext(users)
        }
        self.numberFollowings.onNext(count - 1)
    }
    
    fileprivate func add(user: UserPublic) {
        guard let count = try? self.numberFollowings.value() else { return }
        self.numberFollowings.onNext(count + 1)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.openVisitorPage {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        }
    }

}

extension FollowViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let users = try? self.users.value() else { return .zero }
        return UserFollowCollectionViewCell.size(user: users[indexPath.row].profile, in: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}

extension FollowViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.collectionView.contentOffset.y >= self.collectionView.contentSize.height - self.collectionView.frame.height {
            if transition.y < -70 {
                self.statusShow = .more
                self.page.onNext(((try? self.page.value()) ?? 0) + 1)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if Status.reachable.value {
            let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
            if scrollView.contentOffset.y == 0 {
                if transition.y > 100 {
                    self.statusShow = .new
                    self.page.onNext(1)
                    self.getNumberFollow()
                }
            }
        }
    }
}


extension FollowViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
extension FollowViewController {
    enum FollowType {
        case follower
        case following
    }
}
