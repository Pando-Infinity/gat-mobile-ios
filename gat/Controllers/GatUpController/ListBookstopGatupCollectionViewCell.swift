//
//  ListBookstopGatupCollectionViewCell.swift
//  gat
//
//  Created by jujien on 1/11/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ListBookstopGatupCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { return "listBookstopGatupCell" }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let bookstops: BehaviorRelay<[Bookstop]> = .init(value: [])
    fileprivate let disposeBag = DisposeBag()
    var showBookstop: ((Bookstop) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.register(UINib(nibName: BookstopGatUpCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookstopGatUpCollectionViewCell.identifier)
        self.bookstops.bind(to: self.collectionView.rx.items(cellIdentifier: BookstopGatUpCollectionViewCell.identifier, cellType: BookstopGatUpCollectionViewCell.self)) { (index, bookstop, cell) in
            cell.bookstop.accept(bookstop)
        }.disposed(by: self.disposeBag)
        
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 16.0
            layout.itemSize = .init(width: 135.0, height: 156.0)
            layout.minimumInteritemSpacing = 16.0
            layout.sectionInset = .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
            layout.scrollDirection = .horizontal
        }
        
        self.collectionView.rx.modelSelected(Bookstop.self).subscribe(onNext: { [weak self] (bookstop) in
            self?.showBookstop?(bookstop)
        }).disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13, *) {} else {
            attributes.frame.size = .init(width: UIScreen.main.bounds.width, height: 172.0)
        }
        return attributes
    }

}
