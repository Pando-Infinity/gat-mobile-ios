//
//  BookstopGatUpCollectionViewCell.swift
//  gat
//
//  Created by jujien on 12/31/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BookstopGatUpCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { return "bookstopGatupCell" }

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    let bookstop: BehaviorRelay<Bookstop> = .init(value: .init())
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.bookstop.map { $0.profile?.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.bookstop.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0.profile!.imageId)) }.subscribe(onNext: { [weak self] (url) in
            self?.imageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
            self?.backgroundImageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
        }).disposed(by: self.disposeBag)
        self.imageView.layer.borderColor = UIColor.white.cgColor
        self.imageView.layer.borderWidth = 1.0
        
        self.contentView.backgroundColor = .white
        self.contentView.cornerRadius(radius: 4.0)
        self.dropShadow(offset: .init(width: 2.0, height: 2.0), radius: 4.0, opacity: 0.4, color: UIColor.black.withAlphaComponent(0.4))
        
        self.bookstop.map({ (bookstop) -> String in
            var text = AppConfig.sharedConfig.stringDistance(bookstop.distance)
            if let kind = bookstop.kind as? BookstopKindOrganization, let status = kind.status {
                switch status {
                case .accepted: text = Gat.Text.Gatup.ACECPT_GATUP.localized()//"Đã tham gia"
                case .waitting: text = Gat.Text.Gatup.WAITING_GATUP.localized()//"Chờ phê duyệt"
                }
            }
            return text
        }).bind(to: self.statusLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.circleCorner()
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {} else {
            attributes.frame.size = .init(width: 135.0, height: 150.0)
        }
        return attributes
    }

}
