//
//  BookBookmarkCollectionViewCell.swift
//  gat
//
//  Created by jujien on 9/7/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift

class BookBookmarkCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { return "bookBookmarkCell" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    let book: BehaviorSubject<BookInfo> = .init(value: BookInfo())
    var remove: ((BookInfo) -> Void)?
    var add: ((BookInfo, Int) -> Void)?
    var index: Int = 0
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    fileprivate func setupUI() {
        self.cornerRadius(radius: 5.0)
        self.dropShadow(offset: .init(width: -5.0, height: 5.0), radius: 5.0, opacity: 0.5, color: #colorLiteral(red: 0.8078431373, green: 0.7960784314, blue: 0.7960784314, alpha: 1))
        self.book.map { $0.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0.author }.bind(to: self.authorLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0.descriptionBook }.bind(to: self.descriptionLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0.rateAvg }.subscribe(onNext: {  [weak self] (rating) in
            self?.ratingView.rating = rating
            self?.ratingView.text = String(format: "%.2f", rating)
        }).disposed(by: self.disposeBag)
        self.book.map { URL.init(string: AppConfig.sharedConfig.setUrlImage(id: $0.imageId)) }.subscribe(onNext: { [weak self] (url) in
            self?.bookImageView.sd_setImage(with: url, placeholderImage: BOOK_PLACEHOLDER_ICON)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func event() {
        self.bookmarkButton.rx.tap.asObservable()
            .flatMap { [weak self] (_) -> Observable<BookInfo> in
                guard let book = try? self?.book.value() else { return Observable.empty() }
                return Observable.from(optional: book)
            }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (book) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.remove?(book)
            })
            .flatMap { [weak self] (book) -> Observable<()> in
                return BookNetworkService.shared.saving(bookInfo: book, value: false)
                    .catchError({ [weak self] (error) -> Observable<()> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        if let index = self?.index {
                            self?.add?(book, index)
                        }
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
            })
            .disposed(by: self.disposeBag)
        
    }
}

extension BookBookmarkCollectionViewCell {
    class func size(book: BookInfo, in collectionView: UICollectionView) -> CGSize {
        let imageWidth = (collectionView.frame.width - 24.0) * 0.17
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14.0)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.text = book.title
        let sizeTitle = titleLabel.sizeThatFits(.init(width: collectionView.frame.width - 24.0 - imageWidth - 46.0, height: .infinity))
        let descriptionLabel = UILabel()
        descriptionLabel.font = .systemFont(ofSize: 12.0)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.text = book.descriptionBook
        let sizeDescription = descriptionLabel.sizeThatFits(.init(width: collectionView.frame.width - 24.0 - imageWidth - 46.0, height: .infinity))
        let authorLabel = UILabel()
        authorLabel.font = .systemFont(ofSize: 12.0)
        authorLabel.numberOfLines = 0
        authorLabel.lineBreakMode = .byWordWrapping
        authorLabel.text = book.author
        let sizeAuthor = authorLabel.sizeThatFits(.init(width: collectionView.frame.width - 24.0 - imageWidth - 46.0, height: .infinity))
        return .init(width: collectionView.frame.width - 24.0, height: sizeTitle.height + sizeDescription.height + sizeAuthor.height + 52.0)
    }
}
