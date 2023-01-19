//
//  NavigationItemHomeCollectionViewCell.swift
//  gat
//
//  Created by jujien on 7/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class NavigationItemHomeCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "navigationItemHomeCell" }
    
    @IBOutlet weak var viewCell:UIView!
    
    fileprivate let titleLabel = UILabel()
    fileprivate let imageView = UIImageView()
    
    let navigateItem: BehaviorRelay<NavigateHomeItem?> = .init(value: nil)
    var heightCell: CGFloat = .zero
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .white
        self.layer.masksToBounds = false
        self.contentView.layer.masksToBounds = false
        self.backgroundColor = #colorLiteral(red: 0.9529411765, green: 0.9725490196, blue: 0.9921568627, alpha: 1)
    
    
        self.titleLabel.font = .systemFont(ofSize: 16.0, weight: .semibold)
        self.titleLabel.textColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
        self.navigateItem.map { $0?.image }.bind(to: self.imageView.rx.image).disposed(by: self.disposeBag)
        self.navigateItem.map { $0?.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
                
        self.viewCell.addSubview(self.titleLabel)
        self.viewCell.addSubview(self.imageView)
        self.viewCell.borderColor = #colorLiteral(red: 0.7529411765, green: 0.8588235294, blue: 0.9490196078, alpha: 1)
        self.viewCell.borderWidth = 1
        self.viewCell.backgroundColor = #colorLiteral(red: 0.9529411765, green: 0.9725490196, blue: 0.9921568627, alpha: 1)
        
        self.imageView.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(16.0)
            maker.centerY.equalToSuperview()
        }
        
        self.titleLabel.snp.makeConstraints { (maker) in
            maker.leading.equalTo(self.imageView.snp.trailing).offset(8.0)
            maker.centerY.equalTo(self.imageView.snp.centerY)
        }
        
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 1, green: 0.3098039216, blue: 0.3411764706, alpha: 1)
        self.navigateItem.compactMap { $0?.newStatus }.map { !$0 }.bind(to: view.rx.isHidden).disposed(by: self.disposeBag)
        self.contentView.addSubview(view)
        view.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.height.equalTo(12.0)
            maker.width.equalTo(12.0)
        }
        view.cornerRadius(radius: 6.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.cornerRadius(radius: self.frame.height / 2.0)
        self.viewCell.cornerRadius(radius: self.frame.height / 2.0)
        self.layer.masksToBounds = false
        self.viewCell.layer.masksToBounds = false
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.heightCell != .zero {
            let widthTitle = self.titleLabel.sizeThatFits(.init(width: .infinity, height: self.heightCell - 10.0)).width
            let widthImage = self.imageView.image?.size.width ?? 0.0
            let margin: CGFloat = 16.0
            let spacing: CGFloat = 8.0
            var width: CGFloat = margin + widthImage
            if widthTitle == .zero {
                width += margin
            } else {
                width += spacing + widthTitle + margin
            }
            layout.frame.size = .init(width: width, height: self.heightCell)
        }
        return layout
    }
    
}

extension NavigationItemHomeCollectionViewCell {
    class func size(item: NavigateHomeItem, in bounds: CGSize) -> CGSize {
        let titleLabel = UILabel()
        let imageView = UIImageView()
        titleLabel.font = .systemFont(ofSize: 16.0, weight: .semibold)
        titleLabel.text = item.title
        imageView.image = item.image
        let widthTitle = titleLabel.sizeThatFits(.init(width: .infinity, height: bounds.height - 10.0)).width
        let widthImage = imageView.image?.size.width ?? 0.0
        let margin: CGFloat = 16.0
        let spacing: CGFloat = 8.0
        var width: CGFloat = margin + widthImage
        if widthTitle == .zero {
            width += margin
        } else {
            width += spacing + widthTitle + margin
        }
        return .init(width: width, height: bounds.height - 32.0)
    }
}
