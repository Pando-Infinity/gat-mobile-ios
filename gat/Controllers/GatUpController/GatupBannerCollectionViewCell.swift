//
//  GatupBannerCollectionViewCell.swift
//  gat
//
//  Created by jujien on 12/31/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class GatupBannerCollectionViewCell: UICollectionViewCell {
    class var identifier: String { return "gatupBannerCell" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var lookingInformationButton: UIButton!
    @IBOutlet weak var hideButton: UIButton!
    fileprivate let disposeBag = DisposeBag()
    
    var hideAction: (() -> Void)?
    var showAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.text = Gat.Text.Gatup.BOOKSTOP_ORGANIZATION_GATUP.localized()//"Tủ sách doanh nghiệp GAT-UP"
        self.descriptionLabel.text = Gat.Text.Gatup.BOOKSTOP_ORGANIZATION_DESCRIPTION_GATUP.localized()//"GAT-UP là một chương trình cung cấp tủ sách cho doanh nghiệp để xây dựng văn hóa doanh nghiệp"
        self.lookingInformationButton.setTitle(Gat.Text.Gatup.LOOKING_INFORMATION_GATUP.localized(), for: .normal)
        self.lookingInformationButton.cornerRadius(radius: 4.0)
        self.lookingInformationButton.layer.borderColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        self.lookingInformationButton.layer.borderWidth = 1.0
        
        self.contentView.cornerRadius(radius: 4.0)
        self.dropShadow(offset: .init(width: 2.0, height: 2.0), radius: 4.0, opacity: 0.4, color: UIColor.black.withAlphaComponent(0.4))
        self.hideButton.setTitle(Gat.Text.Gatup.HIDE_GATUP.localized(), for: .normal)
        
        self.lookingInformationButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.showAction?()
        }).disposed(by: self.disposeBag)
        self.hideButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.hideAction?()
        }).disposed(by: self.disposeBag)
        
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {} else {
            let width = UIScreen.main.bounds.width - 32.0
            let height = 206.0 + self.titleLabel.sizeThatFits(.init(width: width - 32.0, height: .infinity)).height + self.descriptionLabel.sizeThatFits(.init(width: width - 32.0, height: .infinity)).height
            attributes.frame.size = .init(width: width, height: height)
        }
        return attributes
    }
}

extension GatupBannerCollectionViewCell {
    class func size(in collectionView: UICollectionView) -> CGSize {
        let width = collectionView.frame.width - 32.0
        let title = UILabel()
        title.text = Gat.Text.Gatup.BOOKSTOP_ORGANIZATION_GATUP.localized()
        title.font = .systemFont(ofSize: 14.0, weight: .semibold)
        title.numberOfLines = 0
        let sizeTitle = title.sizeThatFits(.init(width: width - 32.0, height: .infinity))
        let description = UILabel()
        description.text = Gat.Text.Gatup.BOOKSTOP_ORGANIZATION_DESCRIPTION_GATUP.localized()
        description.font = .systemFont(ofSize: 14.0, weight: .regular)
        description.numberOfLines = 0
        let sizeDescription = description.sizeThatFits(.init(width: width - 32.0, height: .infinity))
        return .init(width: width, height: sizeTitle.height + sizeDescription.height + 206.0)
    }
}
