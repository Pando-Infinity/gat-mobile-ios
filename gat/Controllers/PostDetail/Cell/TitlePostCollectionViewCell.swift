//
//  TitlePostCollectionViewCell.swift
//  gat
//
//  Created by jujien on 5/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Cosmos

class TitlePostCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "titlePostCell" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var ratingTitleLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    
    let post: BehaviorRelay<Post?> = .init(value: nil)
    let sizeCell = BehaviorRelay<CGSize>(value: .zero)
    var openProfile: ((Profile) -> Void)?
    
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.userImageView.circleCorner()
    }
    
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.userImageView.contentMode = .scaleAspectFill
        self.titleLabel.numberOfLines = 0
        self.sizeCell.filter { $0 != .zero }.map { $0.width - 32.0 }.bind { [weak self] (value) in
            self?.titleLabel.preferredMaxLayoutWidth = value
        }.disposed(by: self.disposeBag)
        self.post.map { $0?.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.creator.profile.imageId }
        .map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }
            .bind(to: self.userImageView.rx.url(placeholderImage: DEFAULT_USER_ICON))
            .disposed(by: self.disposeBag)
        
        self.post.compactMap { (post) -> NSAttributedString? in
            guard let post = post else { return nil }
            let attributes = NSMutableAttributedString(string: post.creator.profile.name, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)])
            attributes.append(.init(string: " \(AppConfig.sharedConfig.stringFormatter(from: post.date.publishedDate ?? Date(), format: LanguageHelper.language == .japanese ? "MMMM dd" : "MMMM dd")) • ", attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)]))
            
            return attributes
        }.bind(to: self.nameLabel.rx.attributedText).disposed(by: self.disposeBag)
        
        self.post.map { $0?.categories.first?.title }.bind(to: self.actionButton.rx.title(for: .normal)).disposed(by: self.disposeBag)
        
        self.ratingView.isUserInteractionEnabled = false
        self.post.compactMap { $0?.rating }.bind { [weak self] (value) in
            self?.ratingView.rating = value
        }.disposed(by: self.disposeBag)
        self.post.compactMap { $0?.isReview }.map { !$0 }.bind(to: self.ratingView.rx.isHidden, self.ratingTitleLabel.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    // MARK: -Event
    fileprivate func event() {
        self.userImageView.rx.tapGesture().when(.recognized)
            .withLatestFrom(self.post.compactMap { $0?.creator.profile })
            .bind { [weak self] profile in
                self?.openProfile?(profile)
            }
            .disposed(by: self.disposeBag)
    }
}

extension TitlePostCollectionViewCell {
    class func size(post: Post, in bounds: CGSize) -> CGSize {
        let title = UILabel()
        title.numberOfLines = 0
        title.font = .systemFont(ofSize: 22.0, weight: .semibold)
        title.text = post.title
        let widthSize = UIScreen.main.bounds.width - 32.0
        let sizeTitle = title.sizeThatFits(.init(width: widthSize, height: .infinity))
        
        let spacing: CGFloat = 16.0
        let imageHeight: CGFloat = 21.0
        let ratingHeight: CGFloat = post.isReview ? 27.0 : 0.0
        var height = spacing + sizeTitle.height + spacing + imageHeight + spacing
        if post.isReview {
            height += ratingHeight + spacing
        }
        
        return .init(width: bounds.width, height: height)
    }
}
