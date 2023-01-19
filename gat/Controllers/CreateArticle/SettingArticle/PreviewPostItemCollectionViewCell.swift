//
//  PreviewPostItemCollectionViewCell.swift
//  gat
//
//  Created by jujien on 9/3/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PreviewPostItemCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "previewPostItemCell" }
    
    fileprivate let typeLabel: UILabel = .init()
    fileprivate let containerView: UIView = .init()
    fileprivate let imageView: UIImageView = .init()
    fileprivate let titleLabel: UILabel = .init()
    fileprivate let introLabel: UILabel = .init()
    fileprivate let iconImageView = UIImageView(image: #imageLiteral(resourceName: "camera"))
    fileprivate let cameraLabel = UILabel()
    fileprivate var imageSelection: UIImage?
    
    let item: BehaviorRelay<PreviewArticleItem?> = .init(value: nil)
    var sizeCell = CGSize.zero
    var imageHandler: ((PreviewArticleItem.PreviewType) -> Void)?
    
    fileprivate let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
        self.event()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupType()
        self.setupContainer()
        self.setupImage()
        self.setupTitle()
        self.setupIntro()
        self.configConstrait()
    }
    
    fileprivate func setupType() {
        self.typeLabel.font = .systemFont(ofSize: 14.0, weight: .medium)
        self.typeLabel.textColor = .brownGrey
        self.addSubview(self.typeLabel)
        self.item.map { (item) -> String in
            guard let type = item?.type else { return "" }
            switch type {
            case .small: return "KIND_IMG_TITLE1".localized()
            case .medium: return "KIND_IMG_TITLE2".localized()
            }
        }
        .bind(to: self.typeLabel.rx.text)
        .disposed(by: self.disposeBag)
        
        self.typeLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(16.0)
            maker.height.equalTo(UIFont.systemFont(ofSize: 14.0, weight: .medium).lineHeight)
        }
    }
    
    fileprivate func setupContainer() {
        self.containerView.backgroundColor = .paleGrey
        self.containerView.cornerRadius(radius: 6.0)
        self.addSubview(self.containerView)
        self.containerView.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.typeLabel.snp.bottom).offset(8.0)
            maker.leading.equalToSuperview().offset(16.0)
            maker.trailing.equalToSuperview().offset(-16.0)
            maker.bottom.equalToSuperview()
        }
    }
    
    fileprivate func setupTitle() {
        self.titleLabel.font = .systemFont(ofSize: 16.0, weight: .semibold)
        self.titleLabel.textColor = .navy
        self.titleLabel.numberOfLines = 2
        self.containerView.addSubview(self.titleLabel)
        self.item.compactMap { $0?.post.title }
            .map({ (title) -> String in
                if title.isEmpty { return "INTRO_TITLE_POST".localized() }
                return title
            })
            .bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupIntro() {
        self.introLabel.font = .systemFont(ofSize: 12.0, weight: .regular)
        self.introLabel.textColor = .brownGrey
        self.introLabel.numberOfLines = 2
        self.containerView.addSubview(self.introLabel)
        self.item.compactMap { $0?.post.intro }
            .map({ (intro) -> String in
                if intro.isEmpty { return "INTRO_INTRO_POST".localized() }
                return intro
            })
            .bind(to: self.introLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupImage() {
        self.imageView.contentMode = .scaleAspectFill
        self.item.compactMap { $0 }.map { $0.type == .medium ? $0.post.postImage.coverImage : $0.post.postImage.thumbnailId }.filter { $0.isEmpty }.map { _ in UIImage(named: "article_default_\(Int.random(in: 1...10))") }.bind(to: self.imageView.rx.image).disposed(by: self.disposeBag)
        let share = self.item.compactMap { $0 }.map { $0.type == .medium ? $0.post.postImage.coverImage : $0.post.postImage.thumbnailId }.share().filter { !$0.isEmpty }
        
        share.compactMap { Data(base64Encoded: $0) }.compactMap { UIImage(data: $0) }.bind(to: self.imageView.rx.image).disposed(by: self.disposeBag)
        
        share.compactMap { Data(base64Encoded: $0) }.compactMap { UIImage(data: $0) }.bind { [weak self] image in
            self?.imageSelection = image
        }
        .disposed(by: self.disposeBag)
        share.filter { Data(base64Encoded: $0) == nil }
            .map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0, size: .o)) }
            .bind { [weak self] url in
                let placeholder = self?.imageSelection != nil ? self?.imageSelection : UIImage(named: "article_default_\(Int.random(in: 1...10))")
                self?.imageView.sd_setImage(with: url, placeholderImage: placeholder, completed: { [weak self] (image, _, _, _) in
                    if let image = image {
                        self?.imageSelection = image
                    }
                })
            }
            .disposed(by: self.disposeBag)
//            .bind(to: self.imageView.rx.url(placeholderImage: UIImage(named: "article_default_\(Int.random(in: 1...10))")!)).disposed(by: self.disposeBag)
        self.containerView.addSubview(self.imageView)
        self.item.compactMap { $0?.type }.map { (type) -> CGFloat in
            switch type {
                case .small: return 6.0
                case .medium: return 0.0
            }
        }
        .subscribe(onNext: { [weak self] (value) in
            self?.imageView.cornerRadius(radius: value)
        })
        .disposed(by: self.disposeBag)
        
        self.containerView.addSubview(self.iconImageView)
        self.cameraLabel.text = "CHANGE_COVER_IMG_TITLE".localized()
        self.cameraLabel.font = .systemFont(ofSize: 12.0)
        self.cameraLabel.textColor = .white
        self.containerView.addSubview(self.cameraLabel)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell != .zero {
            layout.frame.size = self.sizeCell
        }
        return layout
    }
    
    // MARK: - Constraint
    fileprivate func configConstrait() {
        self.item.compactMap { $0?.type }.subscribe(onNext: { [weak self] (type) in
            switch type {
                case .small: self?.configSmall()
                case .medium: self?.configMedium()
            }
        })
        .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func configSmall() {
        self.imageView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(12.0)
            maker.leading.equalToSuperview().offset(12.0)
            maker.bottom.equalToSuperview().offset(-12.0)
            maker.width.equalTo(self.imageView.snp.height).multipliedBy(0.7)
        }
        
        self.titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.imageView.snp.top)
            maker.leading.equalTo(self.imageView.snp.trailing).offset(12.0)
            maker.trailing.equalToSuperview().offset(-12.0)
        }
        
        self.introLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(8.0)
            maker.leading.equalTo(self.titleLabel.snp.leading)
            maker.trailing.equalTo(self.titleLabel.snp.trailing)
        }
        
        self.cameraLabel.isHidden = true
        
        self.iconImageView.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(self.imageView.snp.centerX)
            maker.bottom.equalTo(self.imageView.snp.bottom).offset(-5.0)
        }
    }
    
    fileprivate func configMedium() {
        self.imageView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(12.0)
            maker.leading.equalToSuperview().offset(12.0)
            maker.trailing.equalToSuperview().offset(-12.0)
            maker.width.equalTo(self.imageView.snp.height).multipliedBy(64.0 / 27.0)
        }
        
        self.titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.imageView.snp.bottom).offset(8.0)
            maker.leading.equalTo(self.imageView.snp.leading)
            maker.trailing.equalTo(self.imageView.snp.trailing)
        }
        
        self.introLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(4.0)
            maker.leading.equalTo(self.titleLabel.snp.leading)
            maker.trailing.equalTo(self.titleLabel.snp.trailing)
        }
        
        self.cameraLabel.isHidden = false
        
        self.iconImageView.snp.makeConstraints { (maker) in
            maker.leading.equalTo(self.imageView.snp.leading).offset(16.0)
            maker.bottom.equalTo(self.imageView.snp.bottom).offset(-12.0)
        }
        
        self.cameraLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(self.iconImageView.snp.centerY)
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(8.0)
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.imageView.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                guard let type = self?.item.value?.type else { return }
                self?.imageHandler?(type)
            })
            .disposed(by: self.disposeBag)
    }
}
