//
//  BookGatupView.swift
//  gat
//
//  Created by jujien on 1/1/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BookGatupView: UIView {

    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let disposeBag = DisposeBag()
    var showBookDetail: ((BookInfo) -> Void)?
    let editions: BehaviorRelay<[Int]> = .init(value: [])
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.register(UINib.init(nibName: ImageCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: ImageCollectionViewCell.identifier)
        self.editions
            .flatMap { (editions) -> Observable<[BookSharing]> in
                return BookNetworkService.shared.infos(editions: editions)
                    .catchError { (error) -> Observable<[BookSharing]> in
                        return .empty()
                    }
                }
        .bind(to: self.collectionView.rx.items(cellIdentifier: ImageCollectionViewCell.identifier, cellType: ImageCollectionViewCell.self)) { (index, book, cell) in
            if let imageId = book.info?.imageId {
                cell.imageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: imageId)), placeholderImage: DEFAULT_BOOK_ICON)
            }
            cell.cornerRadius(radius: 4.0)
        }
        .disposed(by: self.disposeBag)
        
        if #available(iOS 13.0, *) {
            self.collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(section: self.imageSection())
        } else {
            if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.minimumInteritemSpacing = 16.0
                layout.minimumInteritemSpacing = 16.0
                layout.sectionInset = .zero
                layout.scrollDirection = .horizontal
                layout.itemSize = .init(width: (UIScreen.main.bounds.width - 32.0) * 0.27, height: 130.0)
            }
        }
            
        self.collectionView.rx.modelSelected(BookSharing.self).map { $0.info! }.subscribe(onNext: { [weak self] (book) in
            self?.showBookDetail?(book)
        }).disposed(by: self.disposeBag)
    }
    @available(iOS 13.0, *)
    fileprivate func imageSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 8.0)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 4)

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }

}
