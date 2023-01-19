//
//  MediumArticleBookstopCollectionViewCell.swift
//  gat
//
//  Created by jujien on 8/18/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MediumArticleBookstopCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "mediumArticleBookstopCell" }
    
    let post: BehaviorRelay<Post?> = .init(value: nil)
    var sizeCell: CGSize = .zero
    
    var tapCell:((OpenPostDetail,Bool)->Void)? {
        didSet {
            self.mediumView.tapCell = self.tapCell
        }
    }
    var tapUser:((Bool)-> Void)? {
        didSet {
            self.mediumView.tapUser = self.tapUser
        }
    }
    var tapBook:((Bool)-> Void)? {
        didSet {
            self.mediumView.tapBook = self.tapBook
        }
    }
    
    fileprivate var mediumView: MediumArticleView!
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.mediumView = Bundle.main.loadNibNamed(MediumArticleView.className, owner: self, options: nil)?.first as? MediumArticleView
        self.addSubview(self.mediumView)
        self.post.subscribe(onNext: self.mediumView.post.accept).disposed(by: self.disposeBag)
        self.mediumView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        
        self.cornerRadius(radius: 9.0)
        self.dropShadow(offset: .init(width: 0.0, height: 2.0), radius: 4.0, opacity: 0.5, color: .veryLightPink50)
        self.layer.borderColor = UIColor.veryLightPink18.cgColor
        self.layer.borderWidth = 1.0
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {
            if self.sizeCell != .zero {
                layout.frame.size = self.sizeCell
            }
        }
        return layout
    }
    
    class func size(post: Post, in bounds: CGSize) -> CGSize {
        return MediumArticleView.size(post: post, estimatedSize: bounds)
    }
}
