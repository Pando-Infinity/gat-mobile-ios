//
//  BookstopOrganizationTabCollectionViewCell.swift
//  gat
//
//  Created by jujien on 7/25/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BookstopOrganizationTabCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "bookstopOrganizationTabCell" }
    
    static let HEIGHT: CGFloat = 74.0

    @IBOutlet weak var collectionView: UICollectionView!
    
    let navigateItems: BehaviorRelay<[NavigateHomeItem]> = .init(value: [])
    var showTab: ((NavigateHomeItem) -> Void)?
    var widthCell: CGFloat = .zero
    fileprivate let height: CGFloat = BookstopOrganizationTabCollectionViewCell.HEIGHT
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.register(UINib.init(nibName: NavigationItemHomeCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: NavigationItemHomeCollectionViewCell.identifier)
        let height = self.height - 32.0
        self.collectionView.delegate = self
        //        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
//            layout.estimatedItemSize = .zero//.init(width: 1.0, height: 1.0)
//            layout.scrollDirection = .horizontal
//            layout.minimumInteritemSpacing = 16.0
//            layout.sectionInset = .init(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
//        }
        self.navigateItems
            .bind(to: self.collectionView.rx.items(cellIdentifier: NavigationItemHomeCollectionViewCell.identifier, cellType: NavigationItemHomeCollectionViewCell.self)) { (index, item, cell) in
                cell.navigateItem.accept(item)
                cell.heightCell = height
        }.disposed(by: self.disposeBag)
        
        self.collectionView.rx.modelSelected(NavigateHomeItem.self).subscribe(onNext: { [weak self] (item) in
            self?.showTab?(item)
        })
            .disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attribute = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {
            if self.widthCell != .zero {
                attribute.frame.size = .init(width: self.widthCell, height: self.height + 6.0)
            }
        }
        
        return attribute
    }

}

extension BookstopOrganizationTabCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return NavigationItemHomeCollectionViewCell.size(item: self.navigateItems.value[indexPath.row], in: collectionView.frame.size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
    }
}
