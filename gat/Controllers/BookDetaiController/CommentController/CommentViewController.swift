//
//  DemoViewController.swift
//  gat
//
//  Created by Vũ Kiên on 05/02/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Photos
import Cosmos

protocol ChangeReviewDelegate: class {
    func update(review: Review)
}

class CommentViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var containerWebView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var namBookLabel: UILabel!
    @IBOutlet weak var bottomConstraintWebView: NSLayoutConstraint!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var draftButton: UIButton!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var triggerTextField: UITextField!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate var editorView: CustomEditorView!
    
    weak var delegate: ChangeReviewDelegate?
    let review: BehaviorSubject<Review> = .init(value: Review())
    let readingStatus: BehaviorSubject<ReadingStatus?> = .init(value: nil)
    fileprivate let rating: BehaviorSubject<Double> = .init(value: 0.0)
    fileprivate let disposeBag = DisposeBag()
    fileprivate let currentReview: Review = Review()
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        self.event()
        self.uploadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.editorView.webView.frame.size.height = self.containerWebView.bounds.height
    }
    
    //MARK: - Data
    fileprivate func uploadData() {
        self.sendUpdateReview()
    }
    
    fileprivate func sendUpdateReview() {
        Observable<([String], Review)>
            .combineLatest(
                self.sendEvent(),
                self.review,
                resultSelector: { (value, review) -> ([String], Review) in
                    review.intro = value.1
                    review.reviewType = 2
                    return (value.0, review)
            })
            .flatMapLatest({ [weak self] (base64s, review) -> Observable<Review> in
                return self?.uploadImage(with: base64s)
                    .map({ (html) -> Review in
                        review.review = html
                        review.reviewType = 2
                        return review
                    }) ?? Observable.empty()
            })
            .do(onNext: { [weak self] (_) in
                self?.waiting(true)
            })
            .flatMapLatest { [weak self] (review) in
                ReviewNetworkService
                    .shared
                    .update(review: review)
                    .catchError { [weak self] (error) -> Observable<(Review, Double)> in
                        HandleError.default.showAlert(with: error)
                        self?.waiting(false)
                        self?.reset()
                        return Observable.empty()
                }
            }
            .do(onNext: { [weak self] (review, _) in
                self?.waiting(false)
                self?.delegate?.update(review: review)
            })
            .flatMapLatest { (review, _) in
                Repository<Review, ReviewObject>.shared.save(object: review)
            }
            .subscribe(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func uploadImage(with base64s: [String]) -> Observable<String> {
        var urls: [String] = []
        return Observable<[String]>
            .just(base64s)
            .flatMapLatest { [weak self] (base64s) -> Observable<String> in
                if base64s.isEmpty {
                    return self?.getHtml(urls: []) ?? Observable.empty()
                } else {
                    return Observable<String>
                        .from(base64s)
                        .flatMapLatest { (base64) -> Observable<String> in
                            guard let data = Data(base64Encoded: base64), let image = UIImage(data: data) else {
                                return Observable.error(ServiceError(domain: "Image", code: -1, userInfo: ["message": "Image Error"]))
                            }
                            guard let imageResize = image.resizeAndCompress(0.8, maxBytes: 1000*1000) else {
                                return Observable.error(ServiceError(domain: "Image", code: -1, userInfo: ["message": "Image Error"]))
                            }
                            return Observable<String>.just(imageResize.toBase64())
                        }
                        .catchError({ (error) -> Observable<String> in
                            HandleError.default.showAlert(with: error)
                            urls = []
                            return Observable.empty()
                        })
                        .filter { !$0.isEmpty && Status.reachable.value }
                        .flatMapLatest { [weak self] (base64) in
                            CommonNetworkService
                                .shared
                                .uploadImage(base64: base64)
                                .catchError { [weak self] (error) -> Observable<String> in
                                    self?.waiting(false)
                                    HandleError.default.showAlert(with: error)
                                    urls = []
                                    return Observable.empty()
                            }
                        }
                        .map { AppConfig.sharedConfig.setUrlImage(id: $0, size: .o) }
                        .do(onNext: { (url) in
                            urls.append(url)
                        })
                        .filter { _ in urls.count == base64s.count }
                        .flatMapLatest { [weak self] (_) -> Observable<String> in
                            return self?.getHtml(urls: urls) ?? Observable.empty()
                        }
                }
        }
    }
    
    fileprivate func getHtml(urls: [String]) -> Observable<String> {
        return Observable<String>
            .create({ [weak self] (observer) -> Disposable in
                self?.editorView.getContent(urls: urls, content: { (html) in
                    observer.onNext(html)
                }, error: { (error) in
                    observer.onError(ServiceError(domain: "Javascript", code: -1, userInfo: ["message": error.localizedDescription]))
                })
                return Disposables.create()
            })
            .catchError({ [weak self] (error) -> Observable<String> in
                self?.waiting(false)
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            })
    }
    
    fileprivate func getListImageBas64() -> Observable<[String]> {
        return Observable<[String]>
            .create({ [weak self] (observer) -> Disposable in
                self?.editorView.getListImageBase64({ (value) in
                    observer.onNext(value ?? [])
                }, error: { (error) in
                    observer.onError(ServiceError(domain: "Javascript", code: -1, userInfo: ["message": error.localizedDescription]))
                })
                return Disposables.create()
            })
            .catchError({ (error) -> Observable<[String]> in
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            })
    }
    
    fileprivate func getIntro() -> Observable<String> {
        return Observable<String>
            .create({ [weak self] (observer) -> Disposable in
                self?.editorView.getIntro({ (intro) in
                    observer.onNext(intro)
                }, error: { (error) in
                    observer.onError(ServiceError(domain: "Javascript", code: -1, userInfo: ["message": error.localizedDescription]))
                })
                return Disposables.create()
            })
            .catchError({ (error) -> Observable<String> in
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            })
    }
    
    fileprivate func reset() {
        guard let review = try? self.review.value() else {
            return
        }
        review.intro = self.currentReview.intro
        review.review = self.currentReview.review
        review.value = self.currentReview.value
    }
    
    //MARK: - UI
    fileprivate func setup() {
        self.rateLabel.text = Gat.Text.Comment.RATE_TITLE.localized()
        self.setupEditorView()
        self.triggerTextField.becomeFirstResponder()
        self.setupLoading()
        self.draftButton.isHidden = true
        self.setupReview()
    }
    
    fileprivate func setupReview() {
        self.review
            .subscribe(onNext: { [weak self] (review) in
                self?.ratingView.rating = review.value
                self?.namBookLabel.text = review.book?.title
                self?.editorView.html = review.review
                    .replacingOccurrences(of: "\n", with: "\\n")
                    .replacingOccurrences(of: "\'", with: "\\\'")
                    .replacingOccurrences(of: "\r", with: "")
                self?.currentReview.review = review.review
                self?.currentReview.intro = review.intro
                self?.currentReview.value = review.value
                self?.rating.onNext(review.value)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupEditorView() {
        self.view.layoutIfNeeded()
        self.editorView = CustomEditorView(frame: self.containerWebView.bounds)
        self.editorView.placeholder = Gat.Text.Comment.EDIT_PLACEHOLDER
        self.editorView.layer.masksToBounds = true
        self.containerWebView.addSubview(self.editorView)
    }
    
    fileprivate func setupLoading() {
        let urlGif = Bundle.main.url(forResource: LOADING_GIF, withExtension: EXTENSION_GIF)
        self.loadingView.sd_setImage(with: urlGif!)
        self.loadingView.isHidden = true
    }
    
    fileprivate func waiting(_ isWaiting: Bool) {
        self.loadingView.isHidden = !isWaiting
        self.sendButton.isHidden = isWaiting
        self.containerWebView.isUserInteractionEnabled = !isWaiting
    }
    
    fileprivate func showAlertNotification() {
        let okAction = ActionButton(titleLabel: Gat.Text.Comment.YES_ALERT_TITLE.localized()) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        let noAction = ActionButton(titleLabel: Gat.Text.Comment.NO_ALERT_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: Gat.Text.Comment.NOTIFICATION_CANCEL_COMMENT.localized(), message: Gat.Text.Comment.CANCEL_COMMENT_MESSAGE.localized(), actions: [okAction, noAction], in: self)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.draftButtonEvent()
        self.changeRatingEvent()
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboard(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboard(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc fileprivate func handleKeyboard(notification: Notification) {
        guard notification.name == UIResponder.keyboardWillShowNotification else {
            return
        }
        guard let rect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.view.layoutIfNeeded()
        self.editorView.webView.frame.size.height = self.containerWebView.frame.height - rect.height
        self.view.layoutIfNeeded()
    }
    
    fileprivate func draftButtonEvent() {
    }
    
    fileprivate func changeRatingEvent(){
        self.ratingView.didFinishTouchingCosmos = { [weak self] (rating) in
            guard let value = try? self?.review.value(), let review = value else {
                return
            }
            review.value = rating
            self?.review.onNext(review)
        }
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .tap.asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.showAlertNotification()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func sendEvent() -> Observable<([String], String)> {
        return self.sendButton
            .rx
            .controlEvent(.touchUpInside)
            .do(onNext: { [weak self] (_) in
                self?.waiting(true)
            })
            .flatMapLatest { [weak self] (_) -> Observable<([String], String)> in
                return Observable<([String], String)>
                    .combineLatest(
                        self?.getListImageBas64() ?? Observable.empty(),
                        self?.getIntro() ?? Observable.empty(),
                        resultSelector: { ($0, $1) })
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension CommentViewController: UINavigationControllerDelegate {
    
}

extension CommentViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
