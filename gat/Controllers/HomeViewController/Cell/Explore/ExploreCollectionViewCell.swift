//
//  ExploreCollectionViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol ExploreCollectionCellDelegate: class {
    func showExplore(_ exploration: Exploration)
}

class ExploreCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: ExploreCollectionCellDelegate?
    fileprivate let disposeBag = DisposeBag()
    fileprivate var exploration: Exploration!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.containerView.cornerRadius(radius: 5.0)
        self.containerView.dropShadow(offset: .zero, radius: 5.0, opacity: 0.72, color: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1))
        self.event()
    }
    
    func setup(exploration: Exploration) {
        self.exploration = exploration
        self.imageView.image = exploration.image
        self.titleLabel.text = exploration.title
        self.iconImageView.image = exploration.icon
        if case .item(let bookstop) = exploration {
            self.iconImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookstop.profile!.imageId)), placeholderImage: exploration.icon)
            self.imageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookstop.profile!.coverImageId)), placeholderImage: exploration.image)
        }
        
        self.layoutIfNeeded()
        if #available(iOS 11.0, *) {
            self.imageView.layer.cornerRadius = 5.0
            self.imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            let shape = CAShapeLayer()
            shape.bounds = self.imageView.frame
            shape.position = self.imageView.center
            shape.path = UIBezierPath(roundedRect: self.imageView.bounds, byRoundingCorners: [.topRight, .topLeft], cornerRadii: CGSize(width: 5.0, height: 5.0)).cgPath
            self.imageView.layer.mask = shape
        }
        self.imageView.layer.masksToBounds = true
        
    }
    
    fileprivate func animation() {
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.containerWidthConstraint.constant = -3.0
            self?.containerHeightConstraint.constant = -3.0
            self?.layoutIfNeeded()
        }) { [weak self] (completed) in
            guard completed else {
                return
            }
            UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                self?.containerWidthConstraint.constant = 0.0
                self?.containerHeightConstraint.constant = 0.0
                self?.layoutIfNeeded()
            }) { [weak self] (completed) in
                self?.showExploreController()
            }
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.tapGestureEvent()
        self.longPressGesture()
    }
    
    fileprivate func tapGestureEvent() {
        self.containerView.rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.animation()
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func longPressGesture() {
        self.containerView.rx
            .longPressGesture(configuration: { (recognized, _) in
                recognized.minimumPressDuration = 0.1
            })
            .when(.began, .ended)
            .bind { [weak self] (gesture) in
                self?.layoutIfNeeded()
                if gesture.state == .began {
                    UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                        self?.containerWidthConstraint.constant = -3.0
                        self?.containerHeightConstraint.constant = -3.0
                        self?.layoutIfNeeded()
                    })
                } else if gesture.state == .ended {
                    UIView.animate(withDuration: 0.1, animations: { [ weak self] in
                        self?.containerWidthConstraint.constant = 0.0
                        self?.containerHeightConstraint.constant = 0.0
                        self?.layoutIfNeeded()
                    })
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showExploreController() {
        self.delegate?.showExplore(self.exploration)
    }
}
