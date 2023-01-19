//
//  BookRequestInfoView.swift
//  gat
//
//  Created by Vũ Kiên on 16/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift

protocol BookRequestInfoDelegate: class {
    func showBookInfo(identifier: String, sender: Any?)
}

class BookRequestInfoView: UIView {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var numberSharingBookLabel: UILabel!
    @IBOutlet weak var numberReviewBookLabel: UILabel!
    
    weak var delegate: BookRequestInfoDelegate?
    fileprivate var bookInfo: BookInfo?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.event()
    }

    func setup(book: BookInfo) {
        self.bookInfo = book
        self.layoutIfNeeded()
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: book.imageId)), placeholderImage: DEFAULT_BOOK_ICON)
        self.titleLabel.text = book.title
        self.authorLabel.text = book.author
        self.setupRatingView(rating: book.rateAvg)
    }
    
    func setup(numberBookSharing: Int, numberReviewBook: Int) {
        self.numberSharingBookLabel.text = "\(numberBookSharing)"
        self.numberReviewBookLabel.text = "\(numberReviewBook)"
    }
    
    fileprivate func setupRatingView(rating: Double) {
        self.layoutIfNeeded()
        self.ratingView.rating = rating
        self.ratingView.text = String(format: "%.2f", rating)
        self.ratingView.settings.starSize = Double(self.ratingView.frame.height)
        self.ratingView.settings.fillMode = .half
    }
    
    fileprivate func event() {
        self.bookImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.delegate?.showBookInfo(identifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.bookInfo)
            })
            .disposed(by: self.disposeBag)
    }
}
