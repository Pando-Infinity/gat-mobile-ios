//
//  UserEvaluationTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 28/02/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift

class UserEvaluationTableViewCell: UITableViewCell {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var nameBookLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var yourRatingTitleLabel: UILabel!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var heightContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var dateEvaluationLabel: UILabel!
    
    weak var controller: ListUserEvaluationViewController?
    fileprivate let disposeBag = DisposeBag()
    fileprivate var review: Review!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.yourRatingTitleLabel.text = Gat.Text.UserProfile.Review.RATING_TITLE.localized()
        self.event()
    }

    // MARK: - UI
    
    func setup(review: Review) {
        self.review = review
        self.setup(bookInfo: review.book!)
        self.setupRateView(rating: review.value)
        self.dateEvaluationLabel.text = AppConfig.sharedConfig.stringFormatter(from: review.evaluationTime, format:         LanguageHelper.language == .japanese ? "yyyy MM, dd" : "MMM dd, yyyy"
)
        self.setupReviewLabel(review: review)
    }
    
    fileprivate func setup(bookInfo: BookInfo) {
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookInfo.imageId)), placeholderImage: DEFAULT_BOOK_ICON)
        self.nameBookLabel.text = bookInfo.title
        self.authorLabel.text = bookInfo.author
    }
    
    fileprivate func setupRateView(rating: Double) {
        self.rateView.rating = rating
        self.layoutIfNeeded()
        self.rateView.settings.starSize = Double(self.rateView.frame.height)
        self.rateView.isUserInteractionEnabled = false
    }
    
    fileprivate func setupReviewLabel(review: Review) {
        if review.reviewType == 1 {
            if review.review.components(separatedBy: " ").count < 175 {
                self.introLabel.text = review.review
            } else {
                let text = review.review.components(separatedBy: " ")[0..<175].joined(separator: " ") +  "...\(Gat.Text.UserProfile.Review.MORE_TITLE.localized())"
                let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]))
                attributes.addAttributes([NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)], range: NSRange(location: text.count - Gat.Text.UserProfile.Review.MORE_TITLE.localized().count, length: Gat.Text.UserProfile.Review.MORE_TITLE.localized().count))
                self.introLabel.attributedText = attributes
            }
        } else if review.reviewType == 2 {
            if review.intro.isEmpty {
                self.introLabel.text = ""
            } else {
                let text = review.intro + "...\(Gat.Text.UserProfile.Review.MORE_TITLE.localized())"
                let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]))
                attributes.addAttributes([NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)], range: NSRange(location: text.count - Gat.Text.UserProfile.Review.MORE_TITLE.localized().count, length: Gat.Text.UserProfile.Review.MORE_TITLE.localized().count))
                self.introLabel.attributedText = attributes
            }
        } else {
            self.introLabel.text = ""
        }
        if !self.introLabel.text!.isEmpty {
            self.introLabel.isHidden = false
            self.heightContainerConstraint.priority = UILayoutPriority.defaultHigh
            self.bottomContainerConstraint.priority = UILayoutPriority.defaultLow
        } else {
            self.introLabel.isHidden = true
            self.heightContainerConstraint.priority = UILayoutPriority.defaultLow
            self.bottomContainerConstraint.priority = UILayoutPriority.defaultHigh
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.showBookEvent()
        self.editButtonEvent()
    }
    
    fileprivate func showBookEvent() {
        self.bookImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.controller?.profileViewController?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.review.book)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func editButtonEvent() {
        self.editButton
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                guard let review = self?.review else {
                    return
                }
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let editAction = UIAlertAction(title: Gat.Text.UserProfile.Review.EDIT_ALERT_TITLE.localized(), style: .default, handler: { [weak self] (_) in
                    self?.controller?.editReview(review)
                })
                let removeAction = UIAlertAction(title: Gat.Text.UserProfile.Review.REMOVE_ALERT_TITLE.localized(), style: .default, handler: { [weak self] (_) in
                    self?.controller?.showAlertDelete(review: review)
                })
                let cancelAction = UIAlertAction.init(title: Gat.Text.UserProfile.Review.CANCEL_ALERT_TITLE.localized(), style: .cancel, handler: nil)
                alert.addAction(editAction)
                alert.addAction(removeAction)
                alert.addAction(cancelAction)
                self?.controller?.present(alert, animated: true, completion: nil)
                
            })
            .disposed(by: self.disposeBag)
    }

}
