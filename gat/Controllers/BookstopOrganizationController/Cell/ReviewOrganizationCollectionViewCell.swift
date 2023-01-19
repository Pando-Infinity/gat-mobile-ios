//
//  ReviewOrganizationCollectionViewCell.swift
//  gat
//
//  Created by jujien on 7/27/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Cosmos

class ReviewOrganizationCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "reviewOrganizationCell" }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameUserLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var rateDateLabel: UILabel!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var reviewImageView: UIImageView!
    @IBOutlet weak var nameBookLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var userContainerView: UIView!
    
    let review = BehaviorRelay<Review?>(value: nil)
    var widthCell: CGFloat = .zero
    var sendBookmark: ((Review) -> Void)?
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.userImageView.circleCorner()
        self.ratingView.settings.starSize = Double(self.ratingView.frame.height)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.ratingView.isUserInteractionEnabled = false
        self.cornerRadius(radius: 5.0)
        self.dropShadow(offset: .zero, radius: 6.0, opacity: 0.5, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
        self.review.map { $0?.user?.name }.bind(to: self.nameUserLabel.rx.text).disposed(by: self.disposeBag)
        self.review.compactMap { $0?.user?.imageId }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }.bind { [weak self] (url) in
            self?.userImageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
        }.disposed(by: self.disposeBag)
        self.review.map { $0?.book?.title }.bind(to: self.nameBookLabel.rx.text).disposed(by: self.disposeBag)
        self.review.map { $0?.book?.author }.bind(to: self.authorLabel.rx.text).disposed(by: self.disposeBag)
        self.review.compactMap { $0?.book?.imageId }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0, size: .b)) }
        .bind { [weak self] (url) in
            self?.reviewImageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
        }.disposed(by: self.disposeBag)
        self.review.compactMap { $0?.evaluationTime }.map { AppConfig.sharedConfig.stringFormatter(from: $0, format:         LanguageHelper.language == .japanese ? "yyyy MM, d" : "MMM d, yyyy") }.bind(to: self.rateDateLabel.rx.text).disposed(by: self.disposeBag)
        self.review.compactMap { $0?.value }.bind { [weak self] (value) in
            self?.ratingView.rating = value
        }.disposed(by: self.disposeBag)
        self.review.compactMap { $0 }.map { $0.reviewType == 1 ? $0.review : $0.intro }.bind(to: self.reviewLabel.rx.text).disposed(by: self.disposeBag)
        self.review.compactMap { $0?.saving }.map { $0 ? #imageLiteral(resourceName: "bookmark-fill-icon") : #imageLiteral(resourceName: "bookmark-blue-icon") }.bind(to: self.bookmarkButton.rx.image(for: .normal)).disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {
            if self.widthCell != .zero {
                let spacing: CGFloat = 4.0
                let margin: CGFloat = 8.0
                let userHeight = self.userContainerView.frame.height
                let imageHeight = self.reviewImageView.frame.height
                let bookHeight = self.nameBookLabel.sizeThatFits(.init(width: self.widthCell - margin * 2.0, height: .infinity)).height
                let authorHeight = self.authorLabel.sizeThatFits(.init(width: self.widthCell - margin * 2.0, height: .infinity)).height
                let reviewHeight = self.reviewLabel.sizeThatFits(.init(width: self.widthCell - margin * 2.0, height: .infinity)).height
                
                let height = userHeight + imageHeight + spacing + bookHeight + spacing + authorHeight + spacing + reviewHeight + margin
                layout.frame.size = .init(width: self.widthCell, height: height)
            }
        }
        
        return layout
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.bookmarkButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (cell) in
                guard let review = cell.review.value else { return }
                cell.bookmarkButton.setImage(review.saving ? #imageLiteral(resourceName: "bookmark-blue-icon") : #imageLiteral(resourceName: "bookmark-fill-icon"), for: .normal)
                cell.sendBookmark?(review)
            })
            .disposed(by: self.disposeBag)
        self.eventTapImageUser()
    }
    
    fileprivate func eventTapImageUser(){
        self.userImageView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            guard let user = self?.review.value?.user else { return }
            if user.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                vc.isShowButton.onNext(true)
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            } else {
                let storyboard = UIStoryboard(name: "VistorProfile", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: UserVistorViewController.className) as! UserVistorViewController
                let userPublic = UserPublic()
                userPublic.profile = user
                vc.userPublic.onNext(userPublic)
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            }
            
        }).disposed(by: self.disposeBag)
    }
}

extension ReviewOrganizationCollectionViewCell {
    class func size(review: Review, in bounds: CGSize) -> CGSize {
        let spacing: CGFloat = 4.0
        let margin: CGFloat = 8.0
        let userHeight: CGFloat = 50.0
        let imageHeight: CGFloat = 180.0
        let bookHeight: CGFloat = 16.0
        let authorHeight: CGFloat = 14.5
        let label = UILabel()
        label.text = review.reviewType == 1 ? review.review : review.intro
        label.font = .systemFont(ofSize: 12.0)
        label.numberOfLines = 3
        let reviewHeight = label.sizeThatFits(.init(width: bounds.width - margin * 2.0, height: .infinity)).height
        let height = userHeight + imageHeight + spacing + bookHeight + spacing + authorHeight + spacing + reviewHeight + margin
        return .init(width: bounds.width - 32.0, height: height)
    }
}
