//
//  BookDetailInPostCollectionViewCell.swift
//  gat
//
//  Created by jujien on 5/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Cosmos

class BookDetailInPostCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "bookDetailInPostCell" }
    
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var imageRatioConstraint: NSLayoutConstraint!
    
    fileprivate let disposeBag = DisposeBag()
    
    let book: BehaviorRelay<BookInfo?> = .init(value: nil)
    let sizeCell: BehaviorRelay<CGSize> = .init(value: .zero)

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.cornerRadius(radius: 5.0)
        self.contentView.layer.borderColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        self.contentView.layer.borderWidth = 1.0
        self.authorLabel.numberOfLines = 2
        self.bookImageView.cornerRadius(radius: 5.0)
        
        Observable.combineLatest(self.sizeCell.filter { $0 != .zero}, Observable.just(self.imageRatioConstraint.multiplier))
            .map { (size, ratio) -> CGFloat in
                let heightImage = size.height - 16.0
                let widthImage = heightImage * ratio
                return size.width - widthImage - 44.0
            }
            .bind { [weak self] (value) in
            self?.authorLabel.preferredMaxLayoutWidth = value
            self?.titleLabel.preferredMaxLayoutWidth = value
        }.disposed(by: self.disposeBag)
        
        self.book.map { $0?.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0?.author }.bind(to: self.authorLabel.rx.text).disposed(by: self.disposeBag)
        self.book.compactMap { $0?.imageId }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }.bind { [weak self] (url) in
            self?.bookImageView.sd_setImage(with: url, placeholderImage: DEFAULT_BOOK_ICON)
        }.disposed(by: self.disposeBag)
        self.book.compactMap { $0?.rateAvg }.bind { [weak self] (value) in
            self?.ratingView.rating = value
        }.disposed(by: self.disposeBag)
        self.ratingView.isUserInteractionEnabled = false
    }
}
