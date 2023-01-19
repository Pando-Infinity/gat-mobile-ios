
//
//  ImageGatupView.swift
//  gat
//
//  Created by jujien on 1/1/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ImageGatupView: UIView {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let disposeBag = DisposeBag()
    let imageIds: BehaviorRelay<[String]> = .init(value: [])
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.register(UINib.init(nibName: ImageCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: ImageCollectionViewCell.identifier)
        self.imageIds.map { $0.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0, size: .b)) } }
            .bind(to: self.collectionView.rx.items(cellIdentifier: ImageCollectionViewCell.identifier, cellType: ImageCollectionViewCell.self)) { [weak self] (index, url, cell) in
                cell.imageView.sd_setImage(with: url)
                cell.cornerRadius(radius: 4.0)
                if self?.imageIds.value.count == 1 {
                    cell.imageView.contentMode = .scaleToFill
                    cell.cornerRadius(radius: 0.0)
                    cell.contentView.cornerRadius(radius: 0.0)
                    cell.layer.borderWidth = 0.0
                    cell.layer.borderColor = UIColor.clear.cgColor
                } else {
                    cell.layer.borderWidth = 1.0
                    cell.layer.borderColor = #colorLiteral(red: 0.9051457047, green: 0.918125093, blue: 0.9214733839, alpha: 1)
                    cell.cornerRadius(radius: 4.0)
                    cell.contentView.cornerRadius(radius: 4.0)
                    //cell.imageView.contentMode = .scaleAspectFit
                    cell.imageView.contentMode = .scaleToFill
                    
                }
                
        }
        .disposed(by: self.disposeBag)
        if #available(iOS 13, *) {} else {
            if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.minimumInteritemSpacing = 16.0
                layout.minimumInteritemSpacing = 16.0
                layout.sectionInset = .zero
                layout.scrollDirection = .horizontal
                self.imageIds.map { $0.count }.subscribe(onNext: { (count) in
                    let width = UIScreen.main.bounds.width - 32.0
                    if count == 1 {
                        layout.itemSize = .init(width: width, height: 314.0)
                    } else {
                        layout.itemSize = .init(width: width/2 , height: 170.0)
                    }
                }).disposed(by: self.disposeBag)
            }
        }
    }
    
    @available(iOS 13.0, *)
    func setupLayout(images: [String]) {
        if images.count == 1 {
            self.collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(section: self.imageSectionSecond())
        } else {
            self.collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(section: self.imageSection())
        }
    }
    
    @available(iOS 13.0, *)
    fileprivate func imageSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 8.0)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }
    
    @available(iOS 13.0, *)
    fileprivate func imageSectionSecond() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }

}
