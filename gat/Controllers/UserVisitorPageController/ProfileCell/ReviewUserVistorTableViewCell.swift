//
//  ReviewUserVistorTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 12/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift

class ReviewUserVistorTableViewCell: UITableViewCell {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var heightContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var evaluationDate: UILabel!
    
    weak var controller: ListReviewVistorUserViewController?
    fileprivate let disposeBag = DisposeBag()
    fileprivate var review: Review!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
        self.ratingLabel.text = Gat.Text.VistorUserProfile.Review.RATING_TITLE.localized()
    }

    // MARK: - UI
    func setup(review: Review) {
        self.review = review
        self.setupBookDetail(review.book!)
        self.setupRateView(rating: review.value)
        self.setupComment(review: review)
        self.evaluationDate.text = AppConfig.sharedConfig.stringFormatter(from: review.evaluationTime, format:         LanguageHelper.language == .japanese ? "yyyy MM dd" : "MMM dd, yyyy"
)
    }
    
    fileprivate func setupBookDetail(_ book: BookInfo) {
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: book.imageId))!, placeholderImage: DEFAULT_BOOK_ICON)
        self.nameLabel.text = book.title
        self.authorLabel.text = book.author
    }
    
    fileprivate func setupRateView(rating: Double) {
        self.layoutIfNeeded()
        self.ratingView.rating = rating
        self.ratingView.settings.starSize = Double(self.ratingView.frame.height)
        self.ratingView.isUserInteractionEnabled = false
    }
    
    fileprivate func setupComment(review: Review) {
        if review.reviewType == 2 {
            if review.intro.isEmpty {
                self.commentLabel.text = ""
            } else {
                let text = review.intro + "...\(Gat.Text.VistorUserProfile.Review.MORE_TITLE.localized())"
                let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]))
                attributes.addAttributes([NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)], range: NSRange(location: text.count - Gat.Text.VistorUserProfile.Review.MORE_TITLE.localized().count, length: Gat.Text.VistorUserProfile.Review.MORE_TITLE.localized().count))
                self.commentLabel.attributedText = attributes
            }
        } else if review.reviewType == 1 {
            if review.review.isEmpty {
                self.commentLabel.text = ""
            } else {
                if (review.review.components(separatedBy: " ").count < 175) {
                    self.commentLabel.text = review.review
                } else {
                    let text = review.review.components(separatedBy: " ")[0..<175].joined(separator: " ") +  "...\(Gat.Text.VistorUserProfile.Review.MORE_TITLE.localized())"
                    let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]))
                    attributes.addAttributes([NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)], range: NSRange(location: text.count - Gat.Text.VistorUserProfile.Review.MORE_TITLE.localized().count, length: Gat.Text.VistorUserProfile.Review.MORE_TITLE.localized().count))
                    self.commentLabel.attributedText = attributes
                }
            }
        } else {
            self.commentLabel.text = ""
        }
        if !self.commentLabel.text!.isEmpty {
            self.commentLabel.isHidden = false
            self.heightContainerConstraint.priority = UILayoutPriority.defaultHigh
            self.bottomContainerConstraint.priority = UILayoutPriority.defaultLow
        } else {
            self.commentLabel.isHidden = true
            self.heightContainerConstraint.priority = UILayoutPriority.defaultLow
            self.bottomContainerConstraint.priority = UILayoutPriority.defaultHigh
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.showBookEdition()
        self.showReview()
    }
    
    fileprivate func showBookEdition() {
        self.bookImageView
            .rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.controller?.userVistorController?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.review.book)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showReview() {
        self.commentLabel
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                guard let review = self?.review else {
                    return
                }
                let storyboard = UIStoryboard(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "ReviewViewController") as! ReviewViewController
                vc.review.onNext(review)
                self?.controller?.userVistorController?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: self.disposeBag)
    }

}
