//
//  VistorUserProfileView.swift
//  gat
//
//  Created by Vũ Kiên on 02/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import ExpandableLabel
class VistorUserProfileView: UIView {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var aboutLabel: ExpandableLabel!
    @IBOutlet weak var totalFollowersLabel: UILabel!
    @IBOutlet weak var totalFollowingsLabel: UILabel!
    @IBOutlet weak var titleFollowersLabel: UILabel!
    @IBOutlet weak var titleFollowsLabel: UILabel!
    @IBOutlet weak var followersView: UIStackView!
    @IBOutlet weak var followingsView: UIStackView!
    @IBOutlet weak var followButton: UIButton!
    
    weak var controller: UserVistorViewController?
    fileprivate var CONSTANT_LEADING_IMAGE: CGFloat = 0.0
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.followButton.cornerRadius(radius: self.followButton.frame.height / 2.0)
        self.titleFollowersLabel.text = Gat.Text.FOLLOWERS_TITLE.localized()
        self.titleFollowsLabel.text = Gat.Text.FOLLOWINGS_TITLE.localized()
        self.event()
        self.aboutLabel.numberOfLines = 3
        self.aboutLabel.delegate = self
        self.aboutLabel.collapsedAttributedLink = NSAttributedString(string: Gat.Text.BookDetail.MORE_TITLE.localized(), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
        self.aboutLabel.expandedAttributedLink = NSAttributedString.init(string: Gat.Text.LESS_TITLE.localized(), attributes:  [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
    }
    
    //MARK: - UI
    func setup(profile: Profile) {
        self.addressLabel.text = profile.address.isEmpty ? "" : "\(Gat.Text.EditUser.ADDRESS_TITLE.localized()): \(profile.address)"
        self.userImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.setupImage()
        self.setupAbout(profile.about)
        
    }
    
    fileprivate func setupAbout(_ about: String) {
        guard !about.isEmpty else { return }
        self.aboutLabel.text = about
        self.aboutLabel.collapsed = true
    }
    
    func setupImage() {
        self.layoutIfNeeded()

//        self.userImageView.layer.borderColor = #colorLiteral(red: 0.8117647059, green: 0.9333333333, blue: 1, alpha: 1)
//        self.userImageView.layer.borderWidth = 1.5
        self.userImageView.circleCorner()
    }
    
    func changeFrame(progress: CGFloat) {
    }
    
    // MARK: Event
    fileprivate func event() {
        self.followersView.rx.tapGesture().when(.recognized)
            .withLatestFrom(Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first })
            .do(onNext: { (userPrivate) in
                if userPrivate == nil {
                    HandleError.default.loginAlert()
                }
            })
            .filter { $0 != nil }
            .subscribe(onNext: { [weak self] (_) in
            self?.controller?.performSegue(withIdentifier: FollowViewController.segueIdentifier, sender: FollowViewController.FollowType.follower)
        }).disposed(by: self.disposeBag)
        
        self.followingsView.rx.tapGesture().when(.recognized)
            .withLatestFrom(Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first })
            .do(onNext: { (userPrivate) in
                if userPrivate == nil {
                    HandleError.default.loginAlert()
                }
            })
            .filter { $0 != nil }
            .subscribe(onNext: { [weak self] (_) in
            self?.controller?.performSegue(withIdentifier: FollowViewController.segueIdentifier, sender: FollowViewController.FollowType.following)
        }).disposed(by: self.disposeBag)
    }
    
}

extension VistorUserProfileView: ExpandableLabelDelegate {
    func willExpandLabel(_ label: ExpandableLabel) {
        self.controller?.view.layoutIfNeeded()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        self.controller?.view.layoutIfNeeded()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        self.controller?.view.layoutIfNeeded()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        self.controller?.view.layoutIfNeeded()
    }
    
    
}
