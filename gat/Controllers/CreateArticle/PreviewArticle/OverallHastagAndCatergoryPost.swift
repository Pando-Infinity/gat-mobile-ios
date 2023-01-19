//
//  OverallHastagAndCatergoryPost.swift
//  gat
//
//  Created by macOS on 11/25/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class OverallHastagAndCatergoryPost: UIView {
    
    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var editButton: UIButton!
    
    fileprivate let disposeBag = DisposeBag()
    
    let items: BehaviorRelay<[PostTagItem]> = .init(value: [])
    
    var tapEdit:((Bool)->Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.register(UINib(nibName: PostTagItemCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: PostTagItemCollectionViewCell.identifier)
        
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .init(width: PostTagItemCollectionViewCell.ESTIMATED_WIDTH, height: PostTagItemCollectionViewCell.HEIGHT)
            layout.minimumInteritemSpacing = 16.0
            layout.sectionInset = .init(top: 2.0, left: 16.0, bottom: 0.0, right: 16.0)
            layout.scrollDirection = .horizontal
        }
        
        self.dropShadow(offset: .init(width: 0.0, height: -4.0), radius: 4.0, opacity: 0.5, color: #colorLiteral(red: 0.7411764706, green: 0.7411764706, blue: 0.7411764706, alpha: 1))
        self.backgroundColor = .white
        
        self.items.bind(to: self.collectionView.rx.items(cellIdentifier: PostTagItemCollectionViewCell.identifier, cellType: PostTagItemCollectionViewCell.self)) { (index, item, cell) in
            cell.heightCell.accept(PostTagItemCollectionViewCell.HEIGHT)
            cell.item.accept(item)
        }.disposed(by: self.disposeBag)
        
        self.editButton.rx.tapGesture()
            .when(.recognized)
            .subscribe { (_) in
                self.tapEdit?(true)
            } onError: { (_) in
                
            } onCompleted: {
                
            } onDisposed: {
                
            }.disposed(by: self.disposeBag)

    }
}
