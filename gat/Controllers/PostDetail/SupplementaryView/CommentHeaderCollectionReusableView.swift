//
//  CommentHeaderCollectionReusableView.swift
//  gat
//
//  Created by jujien on 5/6/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CommentHeaderCollectionReusableView: UICollectionReusableView {
    
    class var identifier: String { "commentHeader" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var popularCommentView: UIStackView!
    @IBOutlet weak var popularCommentLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    
    fileprivate let disposeBag = DisposeBag()
    var selectSortHandler: (() -> Void)?
    let sort: BehaviorRelay<CommentPostFilter> = .init(value: .popular)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    fileprivate func setupUI() {
        self.titleLabel.text = "COMMENT_POST_TITTLE".localized()
        self.sort.map { $0.title }.bind(to: self.popularCommentLabel.rx.text).disposed(by: self.disposeBag)
        self.imageView.image = #imageLiteral(resourceName: "down").withRenderingMode(.alwaysTemplate)
        self.imageView.tintColor = .navy
    }
    
    fileprivate func event() {
        self.popularCommentView.rx.tapGesture().when(.recognized).bind { [weak self] _ in
            self?.selectSortHandler?()
        }
        .disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        layout.zIndex = -1
        return layout
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layoutAttributes.zIndex = -1
    }
    
    class func size(in bounds: CGSize) -> CGSize { .init(width: bounds.width, height: 53.0)}
    
}
