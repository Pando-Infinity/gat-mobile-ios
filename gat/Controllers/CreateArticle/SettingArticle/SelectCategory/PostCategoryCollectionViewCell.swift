//
//  PostCategoryCollectionViewCell.swift
//  gat
//
//  Created by jujien on 9/3/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PostCategoryCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "postCategoryCell" }
    
    fileprivate let titleLabel = UILabel()
    fileprivate let imageView = UIImageView()
    
    fileprivate let disposeBag = DisposeBag()
    
    let item: BehaviorRelay<PostCategory?> = .init(value: nil)
    let itemSelected: BehaviorRelay<Bool> = .init(value: false)
    var sizeCell = CGSize.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    fileprivate func setupUI() {
        self.titleLabel.numberOfLines = 2
        self.addSubview(self.imageView)
        self.addSubview(self.titleLabel)
        
        self.itemSelected.map { $0 ? #imageLiteral(resourceName: "checked") : nil }.bind(to: self.imageView.rx.image).disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.item.compactMap { $0 }, self.itemSelected)
            .map { (item, selected) -> NSAttributedString in
                if selected {
                    return .init(string: item.title, attributes: [.font: UIFont.systemFont(ofSize: 16.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue])
                } else {
                    return .init(string: item.title, attributes: [.font: UIFont.systemFont(ofSize: 16.0, weight: .regular), .foregroundColor: UIColor.navy])
                }
            }
        .bind(to: self.titleLabel.rx.attributedText)
        .disposed(by: self.disposeBag)
        
        self.imageView.snp.makeConstraints { (maker) in
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.width.equalTo(self.imageView.snp.height)
            maker.width.equalTo(18.0)
        }
        
        self.titleLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.trailing.equalTo(self.imageView.snp.leading).offset(12.0)
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell != .zero {
            layout.frame.size = self.sizeCell 
        }
        return layout
    }
}
