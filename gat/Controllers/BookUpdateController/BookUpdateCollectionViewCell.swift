//
//  BookUpdateCollectionViewCell.swift
//  gat
//
//  Created by jujien on 9/8/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class BookUpdateCollectionViewCell: UICollectionViewCell {
    class var identifier: String { return "bookUpdateCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    
    let book = BehaviorSubject<BookUpdate>.init(value: BookUpdate())
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.cornerRadius(radius: 5.0)
        self.dropShadow(offset: .init(width: -5.0, height: 5.0), radius: 5.0, opacity: 0.5, color: #colorLiteral(red: 0.8078431373, green: 0.7960784314, blue: 0.7960784314, alpha: 1))
        self.imageView.sd_setImage(with: URL.init(string: AppConfig.sharedConfig.setUrlImage(id: "")), placeholderImage: DEFAULT_BOOK_ICON)
        self.book.map { $0.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0.note }.bind(to: self.noteLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0.waiting ? Gat.Text.BookUpdate.WAITING_STATUS.localized() : Gat.Text.BookUpdate.UPDATEDED_STATUS.localized() }.bind(to: self.statusLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0.waiting }.subscribe(onNext: { [weak self] (status) in
            self?.statusLabel.textColor = status ? #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 1) : #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        }).disposed(by: self.disposeBag)

        self.book.map { String(format: Gat.Text.BookUpdate.CREATE_DATE_TITLE.localized(), AppConfig.sharedConfig.stringFormatter(from: $0.createDate, format: LanguageHelper.language == .japanese ? "yyyy/MM/dd" : "dd/MM/yyyy")) }.bind(to: self.dateLabel.rx.text).disposed(by: self.disposeBag)
    }
}

extension BookUpdateCollectionViewCell {
    class func size(book: BookUpdate, in collectionView: UICollectionView) -> CGSize {
        let widthImage = (collectionView.frame.width - 24.0) * 0.17
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14.0)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.text = book.title
        let sizeTitle = titleLabel.sizeThatFits(.init(width: collectionView.frame.width - 24.0 - widthImage - 24.0, height: .infinity))
        let noteLabel = UILabel()
        noteLabel.font = .systemFont(ofSize: 12.0)
        noteLabel.numberOfLines = 0
        noteLabel.lineBreakMode = .byWordWrapping
        noteLabel.text = book.note
        let sizeNote = noteLabel.sizeThatFits(.init(width: collectionView.frame.width - 24.0 - widthImage - 24.0, height: .infinity))
        return .init(width: collectionView.frame.width - 24.0, height: sizeTitle.height + sizeNote.height + 46.5)
    }
}
