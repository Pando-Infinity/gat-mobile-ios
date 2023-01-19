//
//  UserReactionCollectionViewCell.swift
//  gat
//
//  Created by jujien on 11/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UserReactionCollectionViewCell: UICollectionViewCell {
    class var identifier: String { "userReactionCell" }
    
    fileprivate let userImageView: UIImageView = .init()
    fileprivate let nameLabel: UILabel = .init()
    fileprivate let subLabel: UILabel = .init()
    fileprivate let seperateView = UIView()
    
    let user: BehaviorRelay<UserReactionInfo?> = .init(value: nil)
    fileprivate let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.userImageView.circleCorner()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.backgroundColor = .white
        self.setupImage()
        self.setupName()
        self.setupSubTitle()
        self.setupSeperate()
    }
    
    fileprivate func setupImage() {
        self.userImageView.contentMode = .scaleAspectFill
        self.user.compactMap { $0?.profile.imageId }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }
            .bind(to: self.userImageView.rx.url(placeholderImage: DEFAULT_USER_ICON))
            .disposed(by: self.disposeBag)
        self.addSubview(self.userImageView)
        self.userImageView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(16.0)
            maker.width.equalTo(self.userImageView.snp.height)
            maker.top.equalTo(10.0)
        }
        
        let image = UIImageView(image: #imageLiteral(resourceName: "heartbound"))
        self.addSubview(image)
        image.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(self.userImageView.snp.bottom)
            maker.trailing.equalTo(self.userImageView.snp.trailing).offset(4.0)
        }
    }
    
    fileprivate func setupName() {
        self.nameLabel.textColor = .navy
        self.nameLabel.font = .systemFont(ofSize: 14.0, weight: .semibold)
        self.nameLabel.numberOfLines = 1
        self.user.map { $0?.profile.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.addSubview(self.nameLabel)
        self.nameLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.userImageView.snp.top)
            maker.leading.equalTo(self.userImageView.snp.trailing).offset(12.0)
            maker.trailing.equalToSuperview().offset(-16.0)
        }
        
    }
    
    fileprivate func setupSubTitle() {
        self.subLabel.textColor = .brownGrey
        self.subLabel.numberOfLines = 1
        self.subLabel.font = .systemFont(ofSize: 12.0)
        self.user.compactMap { $0?.userReaction.reactCount }.map { String(format:"NUMBER_REACTION_POST_TITLE".localized(),$0) }.bind(to: self.subLabel.rx.text).disposed(by: self.disposeBag)
        self.addSubview(self.subLabel)
        self.subLabel.snp.makeConstraints { (maker) in
            maker.leading.equalTo(self.nameLabel.snp.leading)
            maker.trailing.equalToSuperview().offset(-16.0)
            maker.bottom.equalTo(self.userImageView.snp.bottom)
        }
    }
    
    fileprivate func setupSeperate() {
        self.seperateView.backgroundColor = UIColor.paleBlueTwo
        self.addSubview(self.seperateView)
        self.seperateView.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(16.0)
            maker.trailing.equalToSuperview().offset(-16.0)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(1.0)
        }
    }
    
}
