//
//  OwnerPostCollectionViewCell.swift
//  gat
//
//  Created by jujien on 5/6/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class OwnerPostCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "ownerPostCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var ownerPostTitleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    var followHandler: ((PostCreator) -> Void)?
    let owner: BehaviorRelay<PostCreator?> = .init(value: nil)
    let sizeCell: BehaviorRelay<CGSize> = .init(value: .zero)
    var openProfile: ((Profile) -> Void)?
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.circleCorner()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.ownerPostTitleLabel.text = "ARTICLE_BY_TITLE".localized()
        self.followButton.cornerRadius(radius: 4.0)
        self.imageView.contentMode = .scaleAspectFill
        self.owner.map { $0?.profile }.compactMap { $0?.imageId }.map { URL.init(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }.bind { [weak self] (url) in
            self?.imageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
        }.disposed(by: self.disposeBag)
        self.owner.compactMap { $0?.profile }.map { $0.id == Session.shared.user?.id }.bind(to: self.followButton.rx.isHidden).disposed(by: self.disposeBag)
        Observable.combineLatest(self.sizeCell.filter { $0 != .zero }, Observable.just(self.imageView.frame.size), Observable.just(self.followButton.frame.size)).map { (sizeCell, sizeImage, sizeButton) -> CGFloat in
            let spacing: CGFloat = 8.0
            let margin: CGFloat = 8.0
            return sizeCell.width - margin - sizeImage.width - spacing - sizeButton.width - margin
        }.bind { [weak self] (value) in
            self?.nameLabel.preferredMaxLayoutWidth = value
            self?.addressLabel.preferredMaxLayoutWidth = value
        }.disposed(by: self.disposeBag)
        self.owner.map { $0?.profile.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.owner.map { $0?.profile.address }.bind(to: self.addressLabel.rx.text).disposed(by: self.disposeBag)
        self.owner.compactMap { $0?.isFollowing }.map { $0 ? UIColor.fadedBlue : UIColor.white }
            .bind(to: self.followButton.rx.backgroundColor)
            .disposed(by: self.disposeBag)
        self.owner.compactMap { $0?.isFollowing }.map { (value) -> NSAttributedString in
            let text = value ? "FOLLOWING_TITLE".localized() : "+ "+"FOLLOW_TITLE".localized()
            return .init(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: value ? UIColor.white : UIColor.fadedBlue])
        }
        .bind(to: self.followButton.rx.attributedTitle(for: .normal))
        .disposed(by: self.disposeBag)
        self.owner.compactMap { $0?.isFollowing }.bind { [weak self] value in
            self?.followButton.layer.borderWidth = value ? 0.0 : 1.0
            self?.followButton.layer.borderColor = value ? UIColor.clear.cgColor : UIColor.fadedBlue.cgColor
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func event() {
        self.followButton.rx.tap.withLatestFrom(self.owner.compactMap { $0 })
            .bind { [weak self] creator in
                guard Session.shared.isAuthenticated else {
                    HandleError.default.loginAlert()
                    return
                }
                var c = creator
                c.isFollowing = !creator.isFollowing
                let text = c.isFollowing ? "FOLLOWING_TITLE".localized() : "+ "+"FOLLOW_TITLE".localized()
                let attrs = NSAttributedString.init(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: c.isFollowing ? UIColor.white : UIColor.fadedBlue])
                self?.followButton.setAttributedTitle(attrs, for: [])
                self?.followButton.backgroundColor = c.isFollowing ? UIColor.fadedBlue : UIColor.white
                self?.followButton.layer.borderWidth = c.isFollowing ? 0.0 : 1.0
                self?.followButton.layer.borderColor = c.isFollowing ? UIColor.clear.cgColor : UIColor.fadedBlue.cgColor
                self?.followHandler?(c)
            }
            .disposed(by: self.disposeBag)
        
        self.imageView.rx.tapGesture().when(.recognized).withLatestFrom(self.owner.compactMap { $0?.profile })
            .bind { [weak self] user in
                self?.openProfile?(user)
            }
            .disposed(by: self.disposeBag)
    }
}


extension OwnerPostCollectionViewCell {
    class func size(profile: PostCreator, in bounds: CGSize) -> CGSize {
        let padding: CGFloat = 16.0
        let spacing: CGFloat = 8.0
        let widthImage: CGFloat = 60.0
        let followHeight: CGFloat = 30.0
        let titleHeight: CGFloat = 14.0
        let follow = UIButton()
        follow.contentEdgeInsets = .init(top: .zero, left: 10.0, bottom: .zero, right: 10.0)
        follow.setAttributedTitle(.init(string: profile.isFollowing ? "FOLLOWING_TITLE".localized() : "+ "+"FOLLOW_TITLE".localized(), attributes: [.font: UIFont.systemFont(ofSize: 14.0)]), for: .normal)
        let widthFollow = follow.sizeThatFits(.init(width: .infinity, height: followHeight)).width
        let boundsWidth = bounds.width - padding - widthImage - spacing - spacing - widthFollow - padding
        let name = UILabel()
        name.text = profile.profile.name
        name.font = .systemFont(ofSize: 18.0, weight: .semibold)
        name.numberOfLines = 2
        let sizeName = name.sizeThatFits(.init(width: boundsWidth, height: .infinity))
        let address = UILabel()
        address.text = profile.profile.address
        address.numberOfLines = 2
        address.font = .systemFont(ofSize: 14.0)
        let sizeAddress = address.sizeThatFits(.init(width: boundsWidth, height: .infinity))
        var height = padding + titleHeight + spacing / 2.0 + sizeName.height + spacing / 2.0 + sizeAddress.height
        if height < widthImage + padding * 2.0 {
            height = widthImage + padding * 2.0
        }
        
        return .init(width: bounds.width, height: height)
    }
}
