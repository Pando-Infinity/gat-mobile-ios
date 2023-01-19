import UIKit
import Cosmos
import RxSwift

class ReviewBookmarkCollectionViewCell: UICollectionViewCell {
    class var identifier: String { return "reviewBookmarkCell" }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var ratingDateLabel: UILabel!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var forwardImageView: UIImageView!
    @IBOutlet weak var forwardTitleLabel: UILabel!
    @IBOutlet weak var bookView: UIView!
    @IBOutlet weak var userView: UIView!
    
    let review: BehaviorSubject<Review> = .init(value: Review())
    var index: Int = 0
    var remove: ((Review) -> Void)?
    var add: ((Review, Int) -> Void)?
    var perform: ((String, Any?) -> Void)?
    var show: ((UIViewController) -> Void)?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    //MATK: - UI
    fileprivate func setupUI() {
        self.cornerRadius(radius: 5.0)
        self.dropShadow(offset: .init(width: -5.0, height: 5.0), radius: 5.0, opacity: 0.5, color: #colorLiteral(red: 0.8078431373, green: 0.7960784314, blue: 0.7960784314, alpha: 1))
        self.review.flatMap { Observable.from(optional: $0.user?.imageId) }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }.subscribe(onNext: { [weak self] (url) in
            self?.userImageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
            self?.userImageView.circleCorner()
        }).disposed(by: self.disposeBag)
        self.review.map { $0.user?.name }.bind(to: self.usernameLabel.rx.text).disposed(by: self.disposeBag)
        self.review.map {$0.value }.subscribe(onNext: { [weak self] (rating) in
            self?.ratingView.rating = rating
            self?.ratingView.text = String(format: "%0.2f", rating)
        }).disposed(by: self.disposeBag)
        self.review.map { AppConfig.sharedConfig.stringFormatter(from: $0.evaluationTime, format: LanguageHelper.language == .japanese ? "yyyy/MM/dd" : "dd/MM/yyyy") }.bind(to: self.ratingDateLabel.rx.text).disposed(by: self.disposeBag)
        self.review.flatMap { (review) -> Observable<NSAttributedString> in
            guard !review.intro.isEmpty else { return Observable.empty() }
            let attributed = NSMutableAttributedString.init(string: review.intro, attributes: [.font: UIFont.systemFont(ofSize: 12.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.2901960784, green: 0.2901960784, blue: 0.2901960784, alpha: 1)])
            attributed.append(NSAttributedString.init(string: "...\(Gat.Text.BookDetail.MORE_TITLE.localized())", attributes: [.font: UIFont.systemFont(ofSize: 12.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.4156862745, green: 0.6784313725, blue: 0.8196078431, alpha: 1)]))
            return Observable.just(attributed)
        }.bind(to: self.reviewLabel.rx.attributedText).disposed(by: self.disposeBag)
        self.review.map { $0.book?.title }.bind(to: self.bookTitleLabel.rx.text).disposed(by: self.disposeBag)
        
        self.forwardTitleLabel.text = Gat.Text.Bookmark.BOOK_DETAIL.localized()
        self.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
        self.forwardImageView.tintColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.showBookDetailEvent()
        self.showUser()
        self.bookmarkEvent()
    }
    
    fileprivate func showBookDetailEvent() {
        self.bookView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            guard let review = try? self?.review.value() else { return }
            self?.perform?("showBookDetail", review?.book)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func showUser() {
        self.userView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            guard let review = try? self?.review.value() else { return }
            if review?.user?.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                let storyboard = UIStoryboard.init(name: "PersonalProfile", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                vc.isShowButton.onNext(true)
                self?.show?(vc)
            } else {
                self?.perform?("showVistorProfile", review?.user)
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func bookmarkEvent() {
        self.bookmarkButton.rx.tap.asObservable()
            .flatMap { [weak self] (_) -> Observable<Review> in
                guard let review = try? self?.review.value() else { return Observable.empty() }
                review?.saving = false
                return Observable.from(optional: review)
            }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (review) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.remove?(review)
            })
            .flatMap { [weak self] (review) -> Observable<()> in
                return ReviewNetworkService.shared.bookmark(review: review)
                    .catchError({ [weak self] (error) -> Observable<()> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        if let index = self?.index {
                            self?.add?(review, index)
                        }
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
            })
            .disposed(by: self.disposeBag)
    }
}

extension ReviewBookmarkCollectionViewCell {
    class func size(review: Review, in collectionView: UICollectionView) -> CGSize {
        let width =  collectionView.frame.width - 24.0
        var sizeReview: CGSize = .zero
        let reviewLabel = UILabel()
        reviewLabel.numberOfLines = 0
        reviewLabel.lineBreakMode = .byWordWrapping
        if !review.intro.isEmpty {
            let attributed = NSMutableAttributedString.init(string: review.intro, attributes: [.font: UIFont.systemFont(ofSize: 12.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.2901960784, green: 0.2901960784, blue: 0.2901960784, alpha: 1)])
            attributed.append(NSAttributedString.init(string: "...\(Gat.Text.BookDetail.MORE_TITLE.localized())", attributes: [.font: UIFont.systemFont(ofSize: 12.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.4156862745, green: 0.6784313725, blue: 0.8196078431, alpha: 1)]))
            reviewLabel.attributedText = attributed
            sizeReview = reviewLabel.sizeThatFits(.init(width: width - 24.0, height: .infinity))
        }
        return .init(width: width, height: 44.0 + 52.0 + 1.0 + sizeReview.height + 8.0)
    }
}
