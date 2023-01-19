//
//  BookEditionOrganizationShelveTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 14/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift

class BookEditionOrganizationShelveTableViewCell: UITableViewCell {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var borrowerLabel: UILabel!
    @IBOutlet weak var limitedButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    weak var controller: BookstopOrganizationShelveController?
    fileprivate let disposeBag = DisposeBag()
    fileprivate var bookInfo: BookInfo?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.limitedButton.setTitle(Gat.Text.BookstopOrganizaionShelve.LIMITED_BORROW_TITLE.localized(), for: .normal)
        self.messageLabel.text = Gat.Text.BookstopOrganizaionShelve.BOOKSTOP_MEMBER_ONLY_TITLE.localized()
        self.event()
    }
    
    // MARK: - UI
    func setup(userSharingBook: UserSharingBook) {
        self.bookInfo = userSharingBook.bookInfo
        self.setup(bookInfo: userSharingBook.bookInfo)
        self.setupButton()
    }
    
    fileprivate func setup(bookInfo: BookInfo) {
        self.authorLabel.text = bookInfo.author
        self.nameLabel.text = bookInfo.title
        self.setupRatingView(rating: bookInfo.rateAvg)
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookInfo.imageId)), placeholderImage: DEFAULT_BOOK_ICON)
    }
    
    fileprivate func setupButton() {
        self.limitedButton.layer.borderColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1)
        self.limitedButton.layer.borderWidth = 1.2
        self.limitedButton.cornerRadius(radius: 5.0)
    }
    
    fileprivate func setupRatingView(rating: Double) {
        self.layoutIfNeeded()
        self.ratingView.rating = rating
        self.ratingView.text = String.init(format: "%.2f", rating)
        self.ratingView.settings.starSize = Double(self.ratingView.frame.height)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.bookImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.controller?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.bookInfo)
            }
            .disposed(by: self.disposeBag)
    }

}
