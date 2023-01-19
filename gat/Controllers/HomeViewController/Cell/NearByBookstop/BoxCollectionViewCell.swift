//
//  NearbyBookstopCollectionViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol BoxCollectionCellDelegate: class {
    func showView(identifire: String, sender: Any?)
}

class BoxCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var infoContainrView: UIView!
    @IBOutlet weak var bookstopImageView: UIImageView!
    @IBOutlet weak var nameBookstopLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var aboutBookstop: UILabel!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: BoxCollectionCellDelegate?
    fileprivate var bookstop: Bookstop?
    fileprivate var reviewer: Reviewer?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupBox()
        self.event()
    }
    
    // MARK: - UI
    func setup(bookstop: Bookstop) {
        self.bookstop = bookstop
        self.layoutIfNeeded()
        self.bookstopImageView.sd_setImage(with: URL.init(string: AppConfig.sharedConfig.setUrlImage(id: bookstop.profile!.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.bookstopImageView.circleCorner()
        self.aboutBookstop.text = bookstop.profile?.about
        self.nameBookstopLabel.text = bookstop.profile?.name
        self.addressLabel.text = bookstop.profile?.address
    }
    
    func setupReview(reviewer: Reviewer) {
        self.reviewer = reviewer
        self.layoutIfNeeded()
        self.bookstopImageView.sd_setImage(with: URL.init(string: AppConfig.sharedConfig.setUrlImage(id: reviewer.profile!.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.bookstopImageView.circleCorner()
        self.aboutBookstop.text = reviewer.profile?.about
        self.nameBookstopLabel.text = reviewer.profile?.name
        self.addressLabel.text = "\(reviewer.reviewCount) reviews"
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
                if let bookstop = self?.bookstop {
                    if bookstop.profile?.userTypeFlag == .organization {
                        self?.delegate?.showView(identifire: "showBookstopOrganization", sender: bookstop)
                    } else {
                        self?.delegate?.showView(identifire: Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER, sender: bookstop)
                    }
                } else if let reviewer = self?.reviewer {
                    self?.showProfile(reviewer: reviewer)
                }
            }
        }
    }
    
    fileprivate func showProfile(reviewer: Reviewer) {
        Repository<UserPrivate, UserPrivateObject>
            .shared.getAll()
            .map { $0.first }
            .withLatestFrom(Observable<Reviewer>.just(reviewer), resultSelector: { ($0, $1) })
            .subscribe(onNext: { [weak self] (userPrivate, reviewer) in
                if userPrivate?.profile?.id == reviewer.profile?.id {
                    self?.delegate?.showView(identifire: "showProfile", sender: nil)
                } else {
                    let userPublic = UserPublic()
                    userPublic.profile = reviewer.profile!
                    self?.delegate?.showView(identifire: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: userPublic)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupBox() {
        self.containerView.cornerRadius(radius: 5.0)
        self.containerView.dropShadow(offset: .zero, radius: 6.0, opacity: 0.5, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
        self.infoContainrView.applyGradient(colors: GRADIENT_BACKGROUND_COLORS)
        
        if #available(iOS 11.0, *) {
            self.infoContainrView.layer.cornerRadius = 5.0
            self.infoContainrView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            let shape = CAShapeLayer()
            shape.bounds = self.infoContainrView.frame
            shape.position = self.infoContainrView.center
            shape.path = UIBezierPath(roundedRect: self.infoContainrView.bounds, byRoundingCorners: [.topRight, .topLeft], cornerRadii: CGSize(width: 5.0, height: 5.0)).cgPath
            self.infoContainrView.layer.mask = shape
        }
        self.infoContainrView.layer.masksToBounds = true
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.containerView.rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.animation()
            }
            .disposed(by: self.disposeBag)
        
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
    
}
