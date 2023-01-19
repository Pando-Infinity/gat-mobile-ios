//
//  ReadingBookDetailViewController.swift
//  gat
//
//  Created by jujien on 1/17/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Cosmos

class ReadingBookDetailViewController: BottomPopupViewController {
    
    class var segueIdentifier: String { return "showReadingBookDetail" }
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var updateReadingButton: UIButton!
    @IBOutlet weak var readingBookTitleLabel: UILabel!
    @IBOutlet weak var silder: GradientSlider!
    @IBOutlet weak var currentPageTextField: UITextField!
    @IBOutlet weak var totalPageTextField: UITextField!
    @IBOutlet weak var completedLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var ratingDateLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var reviewButton: UIButton!
    @IBOutlet weak var rateTopHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var rateTopLowConstraint: NSLayoutConstraint!
    @IBOutlet weak var reviewTopHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var reviewTopLowConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomViewHeightConstraint: NSLayoutConstraint!
    
    override var popupHeight: CGFloat { return 481.0 }
    
    override var popupTopCornerRadius: CGFloat { return 20.0 }
    
    override var popupDismissDuration: Double { return 0.2 }
    
    override var popupPresentDuration: Double { return 0.2 }
    
    override var popupShouldDismissInteractivelty: Bool { return true }
    
    override var popupDimmingViewAlpha: CGFloat { return 0.5 }
    
    var readingDetail: ReadingBookDetailViewModel!
    let isPresent: BehaviorRelay<Bool> = .init(value: false)
    
    fileprivate let review: BehaviorRelay<Review> = .init(value: .init())
    fileprivate var currentRating: Double = 0.0
    fileprivate let newReview = BehaviorRelay<Review>(value: .init())
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
//        self.readingDetail.reading.map { $0.book }
//            .flatMap { (book) -> Observable<Review> in
//                return ReviewNetworkService.shared.review(bookInfo: book)
//                    .catchError { (error) -> Observable<Review> in
//                        HandleError.default.showAlert(with: error)
//                        return .empty()
//                }
//            }
//        .subscribe(onNext: self.review.accept)
//        .disposed(by: self.disposeBag)
        
        self.newReview.skip(1).flatMap { [weak self] (review) -> Observable<(Review, Double)> in
            return ReviewNetworkService.shared.update(review: review)
                .catchError { [weak self] (error) -> Observable<(Review, Double)> in
                    if let review = self?.review.value {
                        review.value = self?.currentRating ?? 0.0
                        self?.review.accept(review)
                    }
                    HandleError.default.showAlert(with: error)
                    return .empty()
            }
        }.map { $0.0 }
            .do(onNext: { [weak self] (_) in
                self?.reviewButton.isEnabled = true
            })
            .subscribe(onNext: self.review.accept)
            .disposed(by: self.disposeBag)
        
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.isPresent.map { $0 ? "" : "Cập nhật tiến độ đọc" }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.isPresent.map { !$0 ? #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 1) : UIColor.white }.bind(to: self.headerView.rx.backgroundColor).disposed(by: self.disposeBag)
        self.isPresent.map { !$0 ? #imageLiteral(resourceName: "back-icon") : #imageLiteral(resourceName: "times") }.bind(to: self.backButton.rx.image(for: .normal)).disposed(by: self.disposeBag)
        self.readButton.setTitle("Đã đọc xong", for: .normal)
        self.updateReadingButton.setTitle("Cập nhật", for: .normal)
        self.setupButtonView()
        self.readingBookTitleLabel.text = "Bạn đã đọc đến trang bao nhiêu?"
        self.rateLabel.text = "Đánh giá"
        self.setupCompletedText()
        self.ratingView.rating = 0.0
        self.setupReadingBook()
        self.setupReview()
        self.ratingView.isUserInteractionEnabled = true
        self.view.isUserInteractionEnabled = true 
    }
    
    fileprivate func setupCompletedText() {
        let completedText = "Hoàn thành!\nHãy đánh giá cuốn sách"
        if let index = completedText.firstIndex(of: "\n") {
            let attributed = NSMutableAttributedString(
                string: String(completedText[completedText.startIndex..<index]),
                attributes: [.font: UIFont.systemFont(ofSize: 18.0, weight: .bold), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)])
            attributed.append(.init(string: String(completedText[index..<completedText.endIndex]),
                                    attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)]))
            self.completedLabel.attributedText = attributed
        } else {
            self.completedLabel.textColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
            self.completedLabel.font = .systemFont(ofSize: 14.0)
            self.completedLabel.text = completedText
        }
        self.readingDetail.reading.map { $0.status != .finish }.bind(to: self.completedLabel.rx.isHidden).disposed(by: self.disposeBag)
        self.readingDetail.reading.map { $0.status }.subscribe(onNext: { [weak self] (status) in
            switch status {
            case .finish:
                self?.rateTopHighConstraint.priority = .defaultLow
                self?.rateTopLowConstraint.priority = .defaultHigh
            case .none, .reading:
                self?.rateTopHighConstraint.priority = .defaultHigh
                self?.rateTopLowConstraint.priority = .defaultLow
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupReadingBook() {
        self.readingDetail.reading.map { "\($0.currentPage)" }.bind(to: self.currentPageTextField.rx.text).disposed(by: self.disposeBag)
        self.readingDetail.reading.map { "\($0.pageNum)" }.bind(to: self.totalPageTextField.rx.text).disposed(by: self.disposeBag)
        self.readingDetail.reading.map { $0.progress }.bind(to: self.silder.rx.value).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupButtonView() {
        if #available(iOS 11.0, *) {
            self.bottomViewHeightConstraint.constant = 72.0 + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0)
        } else {
            self.bottomViewHeightConstraint.constant = 72.0
        }
    }
    
    fileprivate func setupReview() {
        self.review.map { $0.reviewId != 0 }
            .bind(to: self.reviewButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
        
        self.review.map { $0.value }.subscribe(onNext: { [weak self] (value) in
            self?.currentRating = value
            self?.ratingView.rating = value
        }).disposed(by: self.disposeBag)
        
        let review = self.review.map { $0.reviewType == 1 ? "\($0.review)" : "\($0.intro)" }.share()
        review.bind(to: self.reviewLabel.rx.text).disposed(by: self.disposeBag)
        
        self.review.map { AppConfig.sharedConfig.stringFormatter(from: $0.evaluationTime, format: LanguageHelper.language == .japanese ? "yyyy MMM dd" : "MMM dd, yyyy") }
            .bind(to: self.ratingDateLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        self.ratingView.backgroundColor = .white
        review.map { $0.isEmpty }.subscribe(onNext: { [weak self] (empty) in
            if empty {
                self?.reviewTopLowConstraint.priority = .defaultLow
                self?.reviewTopHighConstraint.priority = .defaultHigh
            } else {
                self?.reviewTopLowConstraint.priority = .defaultHigh
                self?.reviewTopHighConstraint.priority = .defaultLow
            }
        }).disposed(by: self.disposeBag)
        
        review.map { $0.isEmpty ? "Viết đánh giá" : "Sửa đánh giá" }
            .bind(to: self.reviewButton.rx.title(for: .normal))
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
        self.silderEvent()
        self.textFieldEvent()
        self.ratingEvent()
        self.reviewEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            guard let value = self?.isPresent.value else { return }
            if value {
                self?.dismiss(animated: true, completion: nil)
            } else {
                self?.navigationController?.popViewController(animated: true)
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func silderEvent() {
        self.silder.rx.value.subscribe(onNext: { [weak self] (value) in
            guard let totalPage = self?.readingDetail.reading.value.pageNum else { return }
            let current = 0//Int(totalPage * value)
            self?.currentPageTextField.text = "\(current)"
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func textFieldEvent() {
//        Observable.of(
//            self.currentPageTextField.rx.controlEvent([.editingDidEndOnExit, .editingDidEnd]).asObservable(),
//            self.totalPageTextField.rx.controlEvent([.editingDidEndOnExit, .editingDidEnd]).asObservable(),
//            self.view.rx.tapGesture().when(.recognized).map { _ in }
//        )
//            .merge()
//        self.view.rx.tapGesture().when(.recognized).map { _ in }
//            .subscribe(onNext: { [weak self] (_) in
//                self?.view.endEditing(true)
//            }).disposed(by: self.disposeBag)
        
//        let current = self.currentPageTextField.rx.text.orEmpty.asObservable().flatMap {
//            Observable<Int>.from(optional: Int($0))
//        }
//        let total = self.totalPageTextField.rx.text.orEmpty.asObservable().flatMap {
//            Observable<Int>.from(optional: Int($0))
//        }
//        Observable.combineLatest(current, total)
//            .filter { $0 <= $1 }
//            .map { $0 / $1 }
//            .bind(to: self.silder.rx.value)
//            .disposed(by: self.disposeBag)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapEvent))
        self.view.addGestureRecognizer(tap)
    }
    
    @objc fileprivate func tapEvent() {
        self.view.endEditing(true)
    }
    
    fileprivate func ratingEvent() {
        self.ratingView.didFinishTouchingCosmos = { [weak self] value in
            guard let review = self?.review.value else { return }
            review.value = value
            review.reviewType = 2
            self?.newReview.accept(review)
        }
    }

    fileprivate func reviewEvent() {
        self.reviewButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            guard let review = self?.review.value else { return }
            let storyboard = UIStoryboard.init(name: "BookDetail", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CommentViewController") as! CommentViewController
            vc.delegate = self
            vc.review.onNext(review)
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: self.disposeBag)
    }
}

extension ReadingBookDetailViewController: ChangeReviewDelegate {
    func update(review: Review) {
        self.review.accept(review)
    }
}

extension ReadingBookDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
