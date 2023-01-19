//
//  BookCollectionViewCell.swift
//  Gatbook
//
//  Created by GaT-Kien on 2/21/17.
//  Copyright © 2017 GaT-Kien. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift

protocol BookCollectionDelegate: class {
    func showBookDetail(identifier: String, sender: Any?)
}

class BookCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: BookCollectionDelegate?
    var sizeCell = CGSize.zero
    fileprivate var bookInfo: BookInfo!
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
    }

    // MARK: - UI    
    func setupBook(info: BookInfo) {
        self.bookInfo = info
        self.setupImage(id: info.imageId)
        self.nameLabel.text = info.title
        self.authorLabel.text = info.author
        self.setupRatingView(rating: info.rateAvg)
    }

    fileprivate func setupImage(id: String) {
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: id)), placeholderImage: DEFAULT_BOOK_ICON)
    }
    
    fileprivate func setupRatingView(rating: Double) {
        self.layoutIfNeeded()
        self.rateView.settings.starSize = Double(self.rateView.frame.height)
        self.rateView.rating = rating
        self.rateView.isUserInteractionEnabled = false
    }
    
    fileprivate func animation() {
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.containerWidthConstraint.constant = -5.0
            self?.containerHeightConstraint.constant = -5.0
            self?.layoutIfNeeded()
        }) { [weak self] (completed) in
            guard completed else {
                return
            }
            UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                self?.containerWidthConstraint.constant = 0.0
                self?.containerHeightConstraint.constant = 0.0
                self?.layoutIfNeeded()
            }) { [weak self] (completed) in
                self?.delegate?.showBookDetail(identifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.bookInfo)
            }
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.containerView.rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.animation()
            }
            .disposed(by: self.disposeBag)
        
        self.containerView.rx
            .longPressGesture(configuration: { (recognized, _) in
                recognized.minimumPressDuration = 0.1
            })
            .when(.began, .ended)
            .bind { [weak self] (gesture) in
                self?.layoutIfNeeded()
                if gesture.state == .began {
                    UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                        self?.containerWidthConstraint.constant = -5.0
                        self?.containerHeightConstraint.constant = -5.0
                        self?.layoutIfNeeded()
                    })
                } else if gesture.state == .ended {
                    UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                        self?.containerWidthConstraint.constant = 0.0
                        self?.containerHeightConstraint.constant = 0.0
                        self?.layoutIfNeeded()
                    })
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell != .zero {
            layout.frame.size = self.sizeCell
        }
        return layout
    }
}
