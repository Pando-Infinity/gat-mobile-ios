//
//  BookSuggestReadingCollectionViewCell.swift
//  gat
//
//  Created by jujien on 1/17/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BookSuggestReadingCollectionViewCell: UICollectionViewCell {
    class var identifier: String { return "bookSuggestReadingCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addDescriptionLabel: UILabel!
    
    let book: BehaviorRelay<Book> = .init(value: .init())
    let sizeCell = BehaviorRelay<CGSize>(value: .zero)
    fileprivate var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addDescriptionLabel.preferredMaxLayoutWidth = 90.0
        self.sizeCell.filter { $0 != .zero }.map { $0.width - 170.0 }.bind { [weak self] (value) in
            self?.titleLabel.preferredMaxLayoutWidth = value
            self?.authorLabel.preferredMaxLayoutWidth = value
        }.disposed(by: self.disposeBag)
        self.book.map { URL.init(string: AppConfig.sharedConfig.setUrlImage(id: $0.imageId)) }
            .subscribe(onNext: { [weak self] (url) in
                self?.imageView.sd_setImage(with: url, placeholderImage: DEFAULT_BOOK_ICON)
            }).disposed(by: self.disposeBag)
        self.book.map { $0.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0.author }.bind(to: self.authorLabel.rx.text).disposed(by: self.disposeBag)
        //self.authorLabel.text = "Nam anh test"
        self.addButton.setTitle("BUTTON_ADD".localized(), for: .normal)
        self.addDescriptionLabel.text = "ADD_TO_READING_LIST".localized()
        
        self.setOnClickListener()
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributed = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell.value != .zero {
            attributed.frame.size = self.sizeCell.value
        }
        return attributed
    }
    
    private func setOnClickListener() {
        self.imageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                print("click to cell item")
                let bookInfo = BookInfo()
                bookInfo.editionId = self.book.value.editionId
                bookInfo.bookId = self.book.value.bookId
                SwiftEventBus.post(
                    OpenBookDetailEvent.EVENT_NAME,
                    sender: OpenBookDetailEvent(bookInfo)
                )
            })
        .disposed(by: disposeBag)
    }
    
    @IBAction func onAddBook(_ sender: Any) {
        print("Data when add book: \(self.book.value.editionId)")
        SwiftEventBus.post(
            AddBookToReadingEvent.EVENT_NAME,
            sender: AddBookToReadingEvent(self.book.value.editionId, nil, 0, book.value.numberPage, bookName: book.value.title, readingStatusId: 1)
        )
    }
}
