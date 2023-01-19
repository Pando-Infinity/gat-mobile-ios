//
//  ReviewViewController.swift
//  gat
//
//  Created by Vũ Kiên on 09/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift
import RxCocoa

class ReviewViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var editoButton: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var evaluationDate: UILabel!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookmarkButton: UIButton!
    
    let review = BehaviorSubject<Review>(value: Review())
    weak var delegate: NewReviewDelegate?
    fileprivate var editorView: CustomEditorView!
    fileprivate let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        self.review
            .filter { $0.reviewId != 0 }
            .elementAt(0)
            .filter { _ in Status.reachable.value }
            .do(onNext: { (review) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap {
                ReviewNetworkService.shared
                    .review(reviewId: $0.reviewId)
                    .catchError { (error) -> Observable<Review> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false 
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { [weak self] (review) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.review.onNext(review)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.review.map { $0.book?.title }.subscribe(self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.setupUser()
        self.setupEditorView()
        self.setupRateView()
        self.setupEditButton()
        self.review
            .map { AppConfig.sharedConfig.stringFormatter(from: $0.evaluationTime, format: "MMM dd, yyyy") }
            .subscribe(self.evaluationDate.rx.text)
            .disposed(by: self.disposeBag)
        self.review.map { $0.saving }.subscribe(onNext: { (saving) in
            self.bookmarkButton.setImage(saving ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-blue-icon"), for: .normal)
        })
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupUser() {
        self.view.layoutIfNeeded()
        self.review.map { $0.user?.name }.subscribe(self.usernameLabel.rx.text).disposed(by: self.disposeBag)
        self.review.subscribe(onNext: { [weak self] (review) in
            self?.userImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: review.user!.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        })
            .disposed(by: self.disposeBag)
        
        self.userImageView.circleCorner()
        self.review.map { $0.user?.address }.subscribe(self.addressLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupRateView() {
        self.view.layoutIfNeeded()
        self.review.map { $0.value }.subscribe(onNext: { [weak self] (value) in
            self?.rateView.rating = value
        })
            .disposed(by: self.disposeBag)
        self.rateView.settings.starSize = Double(self.rateView.frame.height)
    }
    
    fileprivate func setupEditorView() {
        self.view.layoutIfNeeded()
        self.editorView = CustomEditorView(frame: self.containerView.bounds)
        self.editorView.frame = self.containerView.bounds
        self.review
            .filter { !$0.review.isEmpty }
            .subscribe(onNext: { [weak self] (review) in
                self?.editorView.html = review.review
                    .replacingOccurrences(of: "\n", with: "\\n")
                    .replacingOccurrences(of: "\'", with: "\\\'")
                    .replacingOccurrences(of: "\r", with: "")
            })
            .disposed(by: self.disposeBag)
        self.editorView.isEditingEnabled = false
        self.containerView.addSubview(self.editorView)
        self.containerView.layer.masksToBounds = true
    }
    
    fileprivate func setupEditButton() {
        self.editoButton.isHidden = true
        Observable
            .combineLatest(Repository<UserPrivate, UserPrivateObject>.shared.getFirst(), self.review, resultSelector: {($0, $1)})
            .map { $0.0.id != $0.1.user?.id }
            .subscribe(self.editoButton.rx.isHidden)
            .disposed(by: self.disposeBag)
        
    }
    
    func showAlertHeader() {
        AlertView.showAlert(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height * self.headerHeightConstraint.multiplier), in: self.view)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backButtonEvent()
        self.editButtonEvent()
        self.showBookDetail()
        self.showUserPage()
        self.bookmarkEvent()
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
    
    fileprivate func editButtonEvent() {
        self.editoButton
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.performSegue(withIdentifier: Gat.Segue.SHOW_COMMENT_IDENTIFIER, sender: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showBookDetail() {
        self.titleLabel
            .rx
            .tapGesture()
            .when(.recognized)
            .withLatestFrom(self.review)
            .subscribe(onNext: { [weak self] (review) in
                self?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: review.book)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showUserPage() {
        self.userImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .withLatestFrom(self.review)
            .withLatestFrom(Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first }, resultSelector: { ($0, $1) })
            .subscribe(onNext: { [weak self] (review, userPrivate) in
                if review.user?.id == userPrivate?.id {
                    let storyBoard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                    let vc = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                    vc.isShowButton.onNext(true)
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    self?.performSegue(withIdentifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: review.user)
                }
            })
            .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func bookmarkEvent() {
        self.bookmarkButton.rx.tap.asObservable()
            .do(onNext: { (_) in
                if !Session.shared.isAuthenticated {
                    HandleError.default.loginAlert()
                }
            })
            .filter { Session.shared.isAuthenticated }
            .flatMap { [weak self] (_) -> Observable<Review> in
                guard let value = try? self?.review.value() else { return Observable.empty() }
                return Observable.from(optional: value)
            }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (review) in
                review.saving = !review.saving
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.bookmarkButton.setImage(!review.saving ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-blue-icon"), for: .normal)
            })
            .flatMapLatest { [weak self] (review) in
                ReviewNetworkService
                    .shared
                    .bookmark(review: review)
                    .catchError({ [weak self] (error) -> Observable<()> in
                        review.saving = !review.saving
                        if let error = error as? ServiceError {
                            let message = error.userInfo?["message"] ?? ""
                            CRNotifications.showNotification(type: .error, title: Gat.Text.CommonError.ERROR_ALERT_TITLE.localized(), message: message, dismissDelay: 1.0)
                        }
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self?.bookmarkButton.setImage(review.saving ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-blue-icon"), for: .normal)
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let value = try? self?.review.value(), let review = value else {
                    return
                }
                CRNotifications.showNotification(type: .success, title: Gat.Text.Home.SUCCESS_TITLE.localized(), message: review.saving ? Gat.Text.Home.ADD_BOOKMARK_MESSAGE.localized() : Gat.Text.Home.REMOVE_BOOKMARK_MESSAGE.localized(), dismissDelay: 1.0)
                self?.delegate?.update(review: review)
                self?.review.onNext(review)
            })
            .disposed(by: self.disposeBag)
        
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_COMMENT_IDENTIFIER {
            let vc = segue.destination as? CommentViewController
            guard let review = try? self.review.value() else { return }
            vc?.review.onNext(review)
            Repository<ReadingStatus, ReadingStatusObject>.shared
                .getAll(predicateFormat: "bookInfo.editionId = %@", args: [review.book!.editionId])
                .map { $0.first }
                .subscribe(onNext: { (readingStatus) in
                    vc?.readingStatus.onNext(readingStatus)
                })
                .disposed(by: self.self.disposeBag)
            vc?.delegate = self
        } else if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            let userPublic = UserPublic()
            userPublic.profile = sender as! Profile
            vc?.userPublic.onNext(userPublic)
        }
    }

}

extension ReviewViewController: ChangeReviewDelegate {
    func update(review: Review) {
        self.review.onNext(review)
    }
}

extension ReviewViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
