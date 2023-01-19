import UIKit
import Cosmos
import RxSwift

protocol NewReviewDelegate: class {
    func update(review: Review)
    
    func showReview(viewcontroller: UIViewController)
}

class NewReviewTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameUserLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var rateDateLabel: UILabel!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var reviewImageView: UIImageView!
    @IBOutlet weak var nameBookLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: NewReviewDelegate?
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let sendBookmark: BehaviorSubject<Bool> = .init(value: false)
    fileprivate let review: BehaviorSubject<Review> = .init(value: Review())
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.containerView.cornerRadius(radius: 5.0)
        self.containerView.dropShadow(offset: .zero, radius: 6.0, opacity: 0.5, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
        self.bookmark()
        self.event()
    }

    // MARK: - Data
    fileprivate func bookmark()  {
        Observable.combineLatest(self.review, self.sendBookmark)
            .filter { $0.1 }
            .map { $0.0 }
            .do(onNext: { (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { $0.reviewId != 0 && Status.reachable.value && Session.shared.isAuthenticated }
            .map { (review) -> Review in
                let copy = Review()
                copy.reviewId = review.reviewId
                copy.saving = !review.saving
                return copy
            }
            .do(onNext: { [weak self] (review) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.bookmarkButton.setImage(review.saving ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-blue-icon"), for: .normal)
            })
            .flatMapLatest { [weak self] (review) in
                ReviewNetworkService
                    .shared
                    .bookmark(review: review)
                    .catchError({ [weak self] (error) -> Observable<()> in
                        if let error = error as? ServiceError {
                            let message = error.userInfo?["message"] ?? ""
                            CRNotifications.showNotification(type: .error, title: Gat.Text.CommonError.ERROR_ALERT_TITLE.localized(), message: message, dismissDelay: 1.0)
                        }
                        self?.sendBookmark.onNext(false)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        if self?.bookmarkButton.imageView?.image == #imageLiteral(resourceName: "bookmark-fill-icon") {
                            self?.bookmarkButton.setImage(#imageLiteral(resourceName: "bookmark-blue-icon"), for: .normal)
                        } else {
                            self?.bookmarkButton.setImage(#imageLiteral(resourceName: "bookmark-fill-icon"), for: .normal)
                        }
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { [weak self] (_) in
                self?.sendBookmark.onNext(false)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                guard let value = try? self?.review.value(), let review = value else {
                    return
                }
                review.saving = !review.saving
                self?.delegate?.update(review: review)
                CRNotifications.showNotification(type: .success, title: Gat.Text.Home.SUCCESS_TITLE.localized(), message: review.saving ? Gat.Text.Home.ADD_BOOKMARK_MESSAGE.localized() : Gat.Text.Home.REMOVE_BOOKMARK_MESSAGE.localized(), dismissDelay: 1.0)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    func setup(review: Review) {
        self.review.onNext(review)
        self.setupUser(profile: review.user!)
        self.setupBook(info: review.book!)
        self.rateDateLabel.text = AppConfig.sharedConfig.stringFormatter(from: review.evaluationTime, format: LanguageHelper.language == .japanese ? "yyyy MMM, d" : "MMM d, yyyy")
        self.setupRateView(rating: review.value)
        self.setupTextReview(review)
        self.setupBookmark(saving: review.saving)
    }
    
    fileprivate func setupUser(profile: Profile) {
        self.layoutIfNeeded()
        self.nameUserLabel.text = profile.name
        self.userImageView.sd_setImage(with: URL.init(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.userImageView.circleCorner()
    }
    
    fileprivate func setupBook(info: BookInfo) {
        self.reviewImageView.sd_setImage(with: URL.init(string: AppConfig.sharedConfig.setUrlImage(id: info.imageId, size: .b)), placeholderImage: DEFAULT_BOOK_ICON)
        self.nameBookLabel.text = info.title
        self.authorLabel.text = info.author
    }
    
    fileprivate func setupRateView(rating: Double) {
        self.layoutIfNeeded()
        self.ratingView.rating = rating
        self.ratingView.settings.starSize = Double(self.ratingView.frame.height)
        self.ratingView.isUserInteractionEnabled = false
    }
    
    fileprivate func setupTextReview(_ review: Review) {
        if review.reviewType == 1 {
            self.reviewLabel.text = review.review
        } else {
            self.reviewLabel.text = review.intro
        }
    }
    
    fileprivate func setupBookmark(saving: Bool) {
        self.bookmarkButton.setImage(saving ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-blue-icon"), for: .normal)
    }
    
    fileprivate func animation() {
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.containerWidthConstraint.constant = -10.0
            self?.containerHeightConstraint.constant = -10.0
            self?.layoutIfNeeded()
        }) { [weak self] (completed) in
            guard completed else {
                return
            }
            UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                self?.containerWidthConstraint.constant = 0.0
                self?.containerHeightConstraint.constant = 0.0
                self?.layoutIfNeeded()
            }) { [weak self] (completed) in
                self?.showReview()
            }
        }
    }

    // MARK: - Event
    fileprivate func event() {
        self.tapContainerEvent()
        self.bookmarkEvent()
        self.showUserEvent()
    }
    
    fileprivate func showReview() {
        do {
            let storyboard = UIStoryboard.init(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ReviewViewController") as! ReviewViewController
            vc.review.onNext(try self.review.value())
            vc.delegate = self.delegate
            self.delegate?.showReview(viewcontroller: vc)
        } catch {
            
        }
        
    }
    
    fileprivate func showUserEvent() {
        self.userButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            guard let value = try? self?.review.value(), let review = value else { return }
            if review.user?.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                let storyboard = UIStoryboard.init(name: "PersonalProfile", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                vc.isShowButton.onNext(true)
                self?.delegate?.showReview(viewcontroller: vc)
            } else {
                let storyboard = UIStoryboard.init(name: "VistorProfile", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: UserVistorViewController.className) as! UserVistorViewController
                let user = UserPublic.init()
                user.profile = review.user!
                vc.userPublic.onNext(user)
                self?.delegate?.showReview(viewcontroller: vc)
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func tapContainerEvent() {
        self.containerView.rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.animation()
            }
            .disposed(by: self.disposeBag)
        self.containerView.rx.longPressGesture { (recognized, delegate) in
            recognized.minimumPressDuration = 0.1
        }
            .when(.began, .ended)
            .bind { [weak self] (gesture) in
                self?.layoutIfNeeded()
                if gesture.state == .began {
                    UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                        self?.containerWidthConstraint.constant = -10.0
                        self?.containerHeightConstraint.constant = -10.0
                        self?.layoutIfNeeded()
                    })
                } else if gesture.state == .ended {
                    UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                        self?.containerWidthConstraint.constant = 0.0
                        self?.containerHeightConstraint.constant = 0.0
                        self?.layoutIfNeeded()
                    })
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func bookmarkEvent() {
        self.bookmarkButton
            .rx
            .controlEvent(.touchUpInside)
            .map { _ in true }
            .subscribe(self.sendBookmark)
            .disposed(by: self.disposeBag)
        
        
    }
}
