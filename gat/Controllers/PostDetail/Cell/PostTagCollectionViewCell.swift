//
//  PostTagCollectionViewCell.swift
//  gat
//
//  Created by jujien on 5/5/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PostTagCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "postTagCell" }

    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let disposeBag = DisposeBag()
    
    let items: BehaviorRelay<[PostTagItem]> = .init(value: [])
    var openHashtag: ((Hashtag) -> Void)?
    var openCategory: ((PostCategory) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.backgroundColor = .white
        self.collectionView.register(UINib(nibName: PostTagItemCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: PostTagItemCollectionViewCell.identifier)
        
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .init(width: PostTagItemCollectionViewCell.ESTIMATED_WIDTH, height: PostTagItemCollectionViewCell.HEIGHT)
            layout.minimumInteritemSpacing = 16.0
            layout.sectionInset = .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
            layout.scrollDirection = .horizontal
        }
        
        self.items.bind(to: self.collectionView.rx.items(cellIdentifier: PostTagItemCollectionViewCell.identifier, cellType: PostTagItemCollectionViewCell.self)) { (index, item, cell) in
            cell.heightCell.accept(PostTagItemCollectionViewCell.HEIGHT)
            cell.item.accept(item)
        }.disposed(by: self.disposeBag)
        self.event()
    }
    
    // MARK: - Event
    fileprivate func event() {
        let share = self.collectionView.rx.modelSelected(PostTagItem.self).share()
        share.filter { $0.image == nil }.map { Hashtag(id: $0.id, name: $0.title, count: 0) }.bind { [weak self] hashtag in
            self?.openHashtag?(hashtag)
        }
        .disposed(by: self.disposeBag)
        
        share.filter { $0.image != nil }.map { PostCategory(categoryId: $0.id, title: $0.title) }.bind { [weak self] category in
            self?.openCategory?(category)
        }
        .disposed(by: self.disposeBag)
    }
}

extension PostTagCollectionViewCell {
    class func size(in bounds: CGSize) -> CGSize { .init(width: bounds.width, height: 60.0) }
}
