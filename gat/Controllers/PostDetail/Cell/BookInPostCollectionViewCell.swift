//
//  BookInPostCollectionViewCell.swift
//  gat
//
//  Created by jujien on 5/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BookInPostCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "bookInPostCell" }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var numBookLabel:UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    
    let books: BehaviorRelay<[BookInfo]> = .init(value: [])
    let sizeCell: BehaviorRelay<CGSize> = .init(value: .zero)
    fileprivate let childSizeCell: BehaviorRelay<CGSize> = .init(value: .zero)
    var openBookDetail: ((BookInfo) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.backgroundColor = .white
        self.backgroundColor = .white
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = "MENTION_BOOK_TITLE".localized()
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.register(UINib(nibName: BookDetailInPostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookDetailInPostCollectionViewCell.identifier)
        self.sizeCell.map { CGSize.init(width: $0.width - 16.0 * 2.0, height: $0.height - 60.0) }.bind(onNext: self.childSizeCell.accept)
            .disposed(by: self.disposeBag)
        
        self.books.bind(to: self.collectionView.rx.items(cellIdentifier: BookDetailInPostCollectionViewCell.identifier, cellType: BookDetailInPostCollectionViewCell.self)) { [weak self] (index, book, cell) in
            cell.book.accept(book)
            cell.sizeCell.accept(self?.childSizeCell.value ?? .zero)
        }.disposed(by: self.disposeBag)
        
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
            layout.minimumLineSpacing = 16.0
            layout.minimumInteritemSpacing = 16.0
            layout.scrollDirection = .horizontal
            self.childSizeCell.bind { (size) in
                layout.itemSize = size
                self.collectionView.reloadData()
            }.disposed(by: self.disposeBag)
        }
        
        self.books.map { $0.count }.map {String(format: "FORMAT_TARGET_BOOK".localized(), $0)}.bind(to: self.numBookLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.collectionView.rx.modelSelected(BookInfo.self)
            .bind { [weak self] book in
                self?.openBookDetail?(book)
            }
            .disposed(by: self.disposeBag)
    }
}

extension BookInPostCollectionViewCell {
    class func size(in bounds: CGSize) -> CGSize {
        return .init(width: bounds.width, height: 200.0)
    }
}
