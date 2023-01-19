//
//  SharingBookStopTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 15/08/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift
import RxCocoa
import RxGesture

class SharingBookStopTableViewCell: UITableViewCell {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var readInPlaceLabel: UILabel!
    @IBOutlet weak var borrowerLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var forwardUIImageView: UIImageView!
    @IBOutlet weak var leadingViewHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingImageStatusLowConstraint: NSLayoutConstraint!
    
    weak var controller: BookCaseViewController?
    fileprivate let disposeBag = DisposeBag()
    fileprivate var userSharingBook: UserSharingBook!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
    }
    
    func setup(userSharingBook: UserSharingBook) {
        self.userSharingBook = userSharingBook
        self.setupBookDetail(book: userSharingBook.bookInfo)
        self.readInPlaceLabel.text = Gat.Text.Bookstop.READ_IN_PLACE_STATUS_TITLE.localized()
        self.borrowerLabel.isHidden = true
        self.statusImageView.isHidden = false
        self.readInPlaceLabel.isHidden = false
        self.button.isHidden = true
        self.statusLabel.isHidden = true
        self.forwardUIImageView.isHidden = true
//        self.leadingViewHighConstraint.priority = UILayoutPriorityDefaultLow
//        self.leadingImageStatusLowConstraint.priority = UILayoutPriorityDefaultHigh
//        self.setNeedsUpdateConstraints()
    }
    
    fileprivate func setupBookDetail(book: BookInfo) {
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: book.imageId)), placeholderImage: DEFAULT_BOOK_ICON)
        self.titleLabel.text = book.title
        self.authorLabel.text = book.author
        self.setupRatingView(rating: book.rateAvg)
    }
    
    fileprivate func setupRatingView(rating: Double) {
        self.rateView.rating = rating
        self.rateView.isUserInteractionEnabled = false
        self.rateView.text = "\(rating)"
        self.layoutIfNeeded()
        self.rateView.settings.starSize = Double(self.rateView.frame.height)
    }
    
    fileprivate func event() {
        self.bookImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (tap) in
                self?.controller?.bookstopController?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.userSharingBook.bookInfo)
            }
            .disposed(by: self.disposeBag)
    }

}
