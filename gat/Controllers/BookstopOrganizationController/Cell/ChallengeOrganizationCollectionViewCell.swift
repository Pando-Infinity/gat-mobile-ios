//
//  ChallengeOrganizationCollectionViewCell.swift
//  gat
//
//  Created by jujien on 7/27/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ChallengeOrganizationCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "challengeOrganizationCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var challengeNameLabel: UILabel!
    @IBOutlet weak var totalJoinLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    
    let challenge = BehaviorRelay<Challenge?>(value: nil)
    var widthCell: CGFloat = .zero
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.cornerRadius(radius: 10.0)
        self.dropShadow(offset: .init(width: 4.0, height: 4.0), radius: 10.0, opacity: 0.1, color: .black)
//        self.contentView.backgroundColor = .white
        self.challenge.map { $0?.title }.bind(to: self.challengeNameLabel.rx.text).disposed(by: self.disposeBag)
        self.challenge.map { String(format: "NUMBER_MEM_CHALLENGE".localized(), $0?.challengeSummary?.totalJoiner ?? 0) }.bind(to: self.totalJoinLabel.rx.text).disposed(by: self.disposeBag)
        self.challenge.compactMap { $0 }.map { TimeUtils.getTimeDuration($0.startDate, $0.endDate) }
            .bind(to: self.dataLabel.rx.text).disposed(by: self.disposeBag)
        self.challenge.compactMap { $0?.imageThumb }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }.bind { [weak self] (url) in
            let path = UIBezierPath(roundedRect: self?.imageView.bounds ?? .zero , byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10.0, height: 10.0))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self?.imageView.layer.mask = mask
            self?.imageView.sd_setImage(with: url, completed: nil)
        }.disposed(by: self.disposeBag)
        
            
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {
            if self.widthCell != .zero {
                let imageHeight: CGFloat = self.imageView.frame.height
                let spacing: CGFloat = 8.0
                let margin: CGFloat = 16.0
                let iconHeight: CGFloat = 17.0
                let nameHeight = self.challengeNameLabel.sizeThatFits(.init(width: self.widthCell - margin, height: .infinity)).height
                let height = imageHeight + margin + nameHeight + spacing + iconHeight + margin
                layout.frame.size = .init(width: self.widthCell, height: height)
            }
        }
        return layout
    }

}

extension ChallengeOrganizationCollectionViewCell {
    class func size(challenge: Challenge, in bounds: CGSize) -> CGSize {
        let spacing: CGFloat = 8.0
        let margin: CGFloat = 16.0
        let iconHeight: CGFloat = 17.0
        let imageHeight: CGFloat = 228.0
        let name = UILabel()
        name.text = challenge.title
        name.font = .systemFont(ofSize: 16.0, weight: .semibold)
        name.numberOfLines = 0
        let nameHeight = name.sizeThatFits(.init(width: bounds.width - margin, height: .infinity)).height
        let height = imageHeight + margin + nameHeight + spacing + iconHeight + margin
        return .init(width: bounds.width - 32.0, height: height)
    }
}
