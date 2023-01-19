//
//  BookDetailViewController.swift
//  gat
//
//  Created by Vũ Kiên on 18/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FBSDKShareKit
import TwitterKit
import HMSegmentedControl
import GoogleMobileAds

protocol BookDetailComponents {
    var book: BehaviorSubject<BookInfo> { get set }
    var bookDetailController: BookDetailViewController? { get set }
}

class BookDetailViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookDetailContainerView: UIView!
    @IBOutlet weak var heightDetailContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var segmentView: BookDetailSegmentView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var admobContainerView: UIView!
    @IBOutlet weak var heightAdmobContainerConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var previousController: UIViewController?
    var controllers: [UIViewController] = []
    fileprivate var bannerView: GADBannerView!
    
    var bookDetailView: BookDetailView!
    var heightComment: CGFloat = 0.0
    var delegate: RemoveBookBookmark?
    fileprivate var relativeYOffset: CGFloat = 0.0

    let bookInfo: BehaviorSubject<BookInfo> = .init(value: BookInfo())
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.getData()
        self.event()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.bannerView.load(GADRequest())
    }

    //MARK: - UI
    fileprivate func setupUI() {
        self.view.layoutIfNeeded()
        self.gradientView.applyGradient(colors: GRADIENT_BACKGROUND_COLORS)
        self.setupBookDetail()
        self.setupSegmentControl()
        self.setupAdmob()
    }
    
    fileprivate func setupSegmentControl() {
        self.segmentView.controller = self
        self.performSegue(withIdentifier: PriceViewController.segueIdentifier, sender: nil)
        self.performSegue(withIdentifier: BookDetailContainerController.segueIdentifier, sender: nil)
    }

    fileprivate func setupBookDetail() {
        self.bookDetailView = Bundle.main.loadNibNamed(Gat.View.BOOKDETAIL, owner: self, options: nil)?.first as? BookDetailView
        self.bookDetailView.frame = self.bookDetailContainerView.bounds
        self.bookDetailView.bookDetailController = self
        self.bookDetailContainerView.addSubview(self.bookDetailView)
    }
    
    func changeFrameProfileView(height: CGFloat) {
        self.heightDetailContainerConstraint.constant = height - self.heightDetailContainerConstraint.multiplier * self.view.frame.height
        let a = height - self.view.frame.height * self.headerViewHeightConstraint.multiplier
        let progress = a / (self.heightDetailContainerConstraint.multiplier * self.view.frame.height - self.view.frame.height * self.headerViewHeightConstraint.multiplier)
        self.detailContainerTopConstraint.constant = -(1.0 - progress) * self.headerViewHeightConstraint.multiplier * self.view.frame.height
        self.bookDetailView.changeFrame(progress: 1.0 - progress)
        self.view.layoutIfNeeded()
    }
    
    fileprivate func setupAdmob() {
        self.view.layoutIfNeeded()
        self.bannerView = GADBannerView(adSize: GADAdSizeBanner)//GADBannerView(adSize: kGADAdSizeBanner)
        self.bannerView.translatesAutoresizingMaskIntoConstraints = true 
        self.admobContainerView.addSubview(self.bannerView)
        if let adId = AppConfig.sharedConfig.config(item: "ad_unit_id") {
            self.bannerView.adUnitID = adId
        }
//        self.bannerView.adUnitID = AppConfig.sharedConfig.get("ad_unit_id")
        self.bannerView.rootViewController = self
        self.heightAdmobContainerConstraint.constant = self.bannerView.adSize.size.height
        self.bannerView.frame.size.width = self.admobContainerView.frame.width
        self.bannerView.frame.origin = .zero
    }

    //MARK: - Data
    func getData() {
        self.getBookInfo()
    }

    fileprivate func getBookInfo() {
        self.processBookInfo()
        self.getBookInfoRepository()
        self.getBookInfoServer()
    }
    
    fileprivate func processBookInfo() {
        self.bookInfo
            .subscribe(onNext: { [weak self] (bookInfo) in
                self?.bookDetailView.bookInfo.onNext(bookInfo)
                self?.controllers
                    .compactMap { $0 as? BookDetailComponents }
                    .forEach({ (component) in
                    component.book.onNext(bookInfo)
                })
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getBookInfoRepository() {
        Observable<BookInfo>
            .from(optional: try? self.bookInfo.value())
            .flatMapLatest {
                Repository<BookInfo, BookInfoObject>
                    .shared
                    .getFirst(predicateFormat: "editionId = %@", args: [$0.editionId])
            }
            .subscribe(onNext: { [weak self] (bookInfo) in
                // Khong lam cho stream bookInfo bị disposed
                self?.bookInfo.onNext(bookInfo)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getBookInfoServer() {
        Observable<(BookInfo, Bool)>
            .combineLatest(Observable<BookInfo>.from(optional: try? self.bookInfo.value()), Status.reachable.asObservable(), resultSelector: { ($0, $1) })
            .filter { (_, status) in status}
            .map { (info, _ ) in info.editionId }
            .filter{ $0 != 0 }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest {
                BookNetworkService.shared
                    .info(editionId: $0)
                    .catchError { (error) -> Observable<BookInfo> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                }
            }
            .do(onNext: { (bookInfo) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .flatMapLatest {
                Observable<((), BookInfo)>
                    .combineLatest(
                        Repository<BookInfo, BookInfoObject>.shared.save(object: $0),
                        Observable<BookInfo>.just($0),
                        resultSelector: { ($0, $1) }
                )
            }
            .map {(_, bookInfo) in bookInfo }
            .subscribe(self.bookInfo)
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
        self.shareEvent()
    }

    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: self.disposeBag)
    }

    fileprivate func shareEvent() {
        self.shareButton
            .rx
            .controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.share()
            }
            .disposed(by: self.disposeBag)
    }
    
    func share() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let facebookAction = UIAlertAction(title: Gat.Text.FACEBOOK_TITLE, style: .default) { [weak self] (action) in
            self?.shareFaceBook()
        }
//        let twitterAction = UIAlertAction(title: Gat.Text.TWITTER_TITLE, style: .default) { [weak self] (action) in
//            self?.shareTwitter()
//        }
        let cancelAction = UIAlertAction(title: Gat.Text.BookDetail.CANCEL_ALERT_TITLE.localized(), style: .cancel)
        alert.addAction(facebookAction)
//        alert.addAction(twitterAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

    fileprivate func shareFaceBook() {
        guard let value = try? self.bookInfo.value() else {
            return
        }
        let content = ShareLinkContent()
        content.contentURL = URL(string: AppConfig.sharedConfig.get("web_url") + "editions/\(value.editionId)")!
        let dialog = ShareDialog.init(fromViewController: self, content: content, delegate: self)
        dialog.show()
    }

    fileprivate func shareTwitter() {
        guard let value = try? self.bookInfo.value() else {
            return
        }
        let composer = TWTRComposer()
        composer.setURL(URL(string: AppConfig.sharedConfig.get("web_url") + "\(value.editionId)"))
        composer.show(from: self) { (result) in
            switch result {
            case .done:
                print("Done!")
                break
            case .cancelled:
                print("cancelled")
                break
            }
        }
    }

    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_LIST_IDENTIFIER {
            let vc = segue.destination as? ListBorrowViewController
            self.bookInfo
                .bind { (bookInfo) in
                    vc?.bookInfo.onNext(bookInfo)
                }
                .disposed(by: self.disposeBag)
        } else if segue.identifier == PostDetailViewController.segueIdentifier {
            let vc = segue.destination as? PostDetailViewController
            vc?.presenter = SimplePostDetailPresenter(post: sender as! Post, imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: vc))
        } else if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        } else if segue.identifier == "showReview" {
            let vc = segue.destination as? ReviewViewController
            vc?.review.onNext(sender as! Review)
        } else if segue.identifier == PriceViewController.segueIdentifier {
            let vc = segue.destination as? PriceViewController
            vc?.bookDetailController = self
        } else if segue.identifier == BookDetailContainerController.segueIdentifier {
            let vc = segue.destination as? BookDetailContainerController
            vc?.bookDetailController = self
        }
    }
}

extension BookDetailViewController: SharingDelegate {
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        
    }
    
    func sharerDidCancel(_ sharer: Sharing) {
        
    }
    
    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        
    }
}

extension BookDetailViewController: ChangeReviewDelegate {
    func update(review: Review) {
        let vc = self.controllers.filter { $0.className == BookDetailContainerController.className }.first as? BookDetailContainerController
        vc?.review.onNext(review)
        vc?.showStatus = .new
        vc?.page.onNext(1)
    }
}

extension BookDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
