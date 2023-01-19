//
//  PostTagItemCollectionViewCell.swift
//  gat
//
//  Created by jujien on 5/5/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PostTagItemCollectionViewCell: UICollectionViewCell {
    class var identifier: String { "postTagItemCell" }
    
    static let ESTIMATED_WIDTH: CGFloat = 130.0
    static let HEIGHT: CGFloat = 26.0
    @IBOutlet weak var titleLeadingLowConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeadingHighConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    let item: BehaviorRelay<PostTagItem?> = .init(value: nil)
    let heightCell: BehaviorRelay<CGFloat> = .init(value: 0.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.cornerRadius(radius: 7.0)
        
        self.item.compactMap { $0 }.map { $0.image == nil }.bind(to: self.imageView.rx.isHidden).disposed(by: self.disposeBag)
        self.item.map { $0?.attributesText }.bind(to: self.titleLabel.rx.attributedText).disposed(by: self.disposeBag)
        self.item.map { $0?.backgroundColor }.bind(to: self.rx.backgroundColor).disposed(by: self.disposeBag)
        self.item.map { $0?.image }.bind(to: self.imageView.rx.image).disposed(by: self.disposeBag)
        self.item.compactMap { $0 }.map { $0.image == nil }.bind { [weak self] (value) in
            self?.titleLeadingLowConstraint.priority = !value ? .defaultLow : .defaultHigh
            self?.titleLeadingHighConstraint.priority = !value ? .defaultHigh : .defaultLow
        }.disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if let item = self.item.value, self.heightCell.value != .zero {
            let widthTitle = item.attributesText.size().width
            let padding: CGFloat = 12.0
            let spacing: CGFloat = 8.0
            let widthImage: CGFloat = item.image == nil ? 0.0 : 15.0
            let width: CGFloat = padding + widthImage + spacing + widthTitle + padding
            attributes.frame.size = .init(width: width, height: self.heightCell.value)
        }
        return attributes
    }

}
