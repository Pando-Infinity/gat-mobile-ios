//
//  ListImageBookstopOrganizationCollectionReusableView.swift
//  gat
//
//  Created by jujien on 7/27/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ListImageBookstopOrganizationCollectionReusableView: UICollectionReusableView {
    
    class var identifier: String { "listImageBookstopOrganizationHeader" }
    
    static let HEIGHT: CGFloat = 231.0
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    fileprivate let disposeBag = DisposeBag()
    var size: CGSize = .zero
    let bookstop: BehaviorRelay<Bookstop?> = .init(value: nil)

    override func awakeFromNib() {
        super.awakeFromNib()
        self.pageControl.currentPage = 0
        let nib = UINib.init(nibName: "ImageCollectionViewCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "imageCollectionCell")
        self.bookstop.compactMap { $0 }
            .map { (bookstop) -> [String] in
                var images: [String] = []
                if !bookstop.profile!.coverImageId.isEmpty {
                    images.append(AppConfig.sharedConfig.setUrlImage(id: bookstop.profile!.coverImageId))
                }
                images.append(contentsOf: bookstop.images.prefix(6).map { $0.url })
                self.pageControl.numberOfPages = images.count
                return images
            }
        .bind(to: self.collectionView.rx.items(cellIdentifier: "imageCollectionCell", cellType: ImageCollectionViewCell.self)) { [weak self] (index, url, cell) in
            cell.imageView.sd_setImage(with: URL(string: url))
            cell.size = self?.size ?? .zero
        }.disposed(by: self.disposeBag)
        
        self.collectionView.rx.didScroll.withLatestFrom(Observable.just(self.collectionView)).compactMap { $0 }
            .map { (collectionView) -> Int in
                var index:Int
                index = Int(abs(collectionView.contentOffset.x) / self.frame.width)
                return index
        }
        .bind(to: self.pageControl.rx.currentPage)
        .disposed(by: disposeBag)
        
        if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            flowLayout.minimumInteritemSpacing = 0.0
            flowLayout.minimumLineSpacing = 0.0
        }
}
    
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {
            if self.size != .zero {
                layout.size = self.size
            }
        }
        return layout
    }
}
