import UIKit
import RxSwift

class UserFollowCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { return "userFollowCell" }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var sharingCountLabel: UILabel!
    @IBOutlet weak var reviewCountLabel: UILabel!
    
    let user = BehaviorSubject<UserPublic>(value: UserPublic())
    let type = BehaviorSubject<FollowViewController.FollowType>.init(value: .follower)
    var currentUser: Profile?
    var removeUser: ((UserPublic) -> Void)?
    var addUser: ((UserPublic) -> Void)?

    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    fileprivate func setupUI() {
        self.layoutIfNeeded()
        self.followButton.cornerRadius(radius: self.followButton.frame.height / 2.0)
        self.user.map { $0.profile.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.user.map { $0.profile.address}.bind(to: self.addressLabel.rx.text).disposed(by: self.disposeBag)
        self.user.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0.profile.imageId)) }
            .subscribe(onNext: { [weak self] (url) in
                self?.imageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
                self?.imageView.circleCorner()
            })
            .disposed(by: self.disposeBag)
        self.user.map { "\($0.sharingCount)" }.bind(to: self.sharingCountLabel.rx.text).disposed(by: self.disposeBag)
        self.user.map { " \($0.reviewCount)" }.bind(to: self.reviewCountLabel.rx.text).disposed(by: self.disposeBag)
        self.user.map { $0.followedByMe }.filter { !$0 }.subscribe(onNext: { [weak self] (_) in
            self?.followButton.setTitle(Gat.Text.FOLLOW_TITLE.localized(), for: .normal)
            self?.followButton.backgroundColor = #colorLiteral(red: 0.2549019608, green: 0.5882352941, blue: 0.7607843137, alpha: 1)
            self?.followButton.setTitleColor(.white, for: .normal)
            self?.followButton.layer.borderColor = UIColor.clear.cgColor
            self?.followButton.layer.borderWidth = 0.0
        }).disposed(by: self.disposeBag)
        
        self.user.map { $0.followedByMe }.filter { $0 }.subscribe(onNext: { [weak self] (_) in
            self?.followButton.setTitle("FOLLOWING_TITLE".localized(), for: .normal)
            self?.followButton.backgroundColor = .white
            self?.followButton.setTitleColor(#colorLiteral(red: 0.2549019608, green: 0.5882352941, blue: 0.7607843137, alpha: 1), for: .normal)
            self?.followButton.layer.borderColor = #colorLiteral(red: 0.2549019608, green: 0.5882352941, blue: 0.7607843137, alpha: 1).cgColor
            self?.followButton.layer.borderWidth = 1.0
        }).disposed(by: self.disposeBag)
        
        self.user.map { $0.profile.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id }.bind(to: self.followButton.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    fileprivate func showAlertUnfollow(user: UserPublic) {
        guard let vc = UIApplication.shared.topMostViewController() else { return }
        let unfollow = ActionButton(titleLabel: Gat.Text.UNFOLLOW_TITLE.localized()) { [weak self] in
            self?.unfollow(user: user)
        }
        let cancel = ActionButton(titleLabel: Gat.Text.CommonError.CANCEL_ERROR_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: String(format: Gat.Text.UNFOLLOW_ALERT_TITLE.localized(), user.profile.name), message: String(format: Gat.Text.UNFOLLOW_MESSAGE.localized(), user.profile.name), actions: [unfollow, cancel], in: vc)
    }
    
    fileprivate func event() {
        let user = self.followButton.rx.tap.asObservable().withLatestFrom(self.user)
        user.filter { $0.followedByMe }
            .subscribe(onNext: { [weak self] (user) in
                self?.showAlertUnfollow(user: user)
            })
            .disposed(by: self.disposeBag)
        
        user.filter { !$0.followedByMe }
            .flatMap { (user) -> Observable<()> in
                return UserFollowService.shared.follow(userId: user.profile.id)
                    .catchError({ (error) -> Observable<()> in
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { [weak self] (_) in
                guard let value = try? self?.user.value(), let user = value, let type = try? self?.type.value() else { return }
                user.followedByMe = true
                self?.user.onNext(user)
                if self?.currentUser?.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id && type == .follower {
                    self?.addUser?(user)
                }
            }).disposed(by: self.disposeBag)

    }
    
    fileprivate func unfollow(user: UserPublic) {
        UserFollowService.shared.unfollow(userId: user.profile.id)
            .catchError({ (error) -> Observable<()> in
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            })
            .subscribe(onNext: { [weak self] (_) in
                guard let value = try? self?.user.value(), let user = value else { return }
                user.followedByMe = false
                self?.user.onNext(user)
                if self?.currentUser?.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                    self?.removeUser?(user)
                }
                
            }).disposed(by: self.disposeBag)

    }
}

extension UserFollowCollectionViewCell {
    class func size(user: Profile, in collectionView: UICollectionView) -> CGSize {
        let name = UILabel()
        name.font = .systemFont(ofSize: 14.0)
        name.text = user.name
        name.numberOfLines = 0
        name.lineBreakMode = .byWordWrapping
        let sizeName = name.sizeThatFits(.init(width: collectionView.frame.width - 101.0 - 320.0 / 3.0, height: .infinity))
        let address = UILabel()
        address.font = .systemFont(ofSize: 12.0)
        address.text = user.address
        address.numberOfLines = 0
        address.lineBreakMode = .byWordWrapping
        let sizeAddress = address.sizeThatFits(.init(width: collectionView.frame.width - 101.0 - 320.0 / 3.0, height: .infinity))
        return .init(width: collectionView.frame.width, height: sizeName.height + sizeAddress.height + 54.0)
    }
}
