//
//  ProfileDetailView.swift
//  gat
//
//  Created by Vũ Kiên on 08/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import ExpandableLabel
import RxCocoa

class ProfileDetailView: UIView {
    
    @IBOutlet weak var profileImageView: UIImageView!
//    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var profileAddressLabel: UILabel!
    @IBOutlet weak var aboutLabel: ExpandableLabel!
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var editTitleLabel: UILabel!
    @IBOutlet weak var totalFollowersLabel: UILabel!
    @IBOutlet weak var totalFollowingsLabel: UILabel!
    @IBOutlet weak var titleFollowersLabel: UILabel!
    @IBOutlet weak var titleFollowsLabel: UILabel!
    @IBOutlet weak var followersView: UIStackView!
    @IBOutlet weak var followingsView: UIStackView!
    
    weak var controller: ProfileViewController?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        LanguageHelper.changeEvent.subscribe(onNext: { [weak self] (_) in
            self?.titleFollowersLabel.text = Gat.Text.FOLLOWERS_TITLE.localized()
            self?.titleFollowsLabel.text = Gat.Text.FOLLOWINGS_TITLE.localized()
            self?.editTitleLabel.text = Gat.Text.UserProfile.EDIT_TITLE.localized()
        }).disposed(by: self.disposeBag)
        self.titleFollowersLabel.text = Gat.Text.FOLLOWERS_TITLE.localized()
        self.titleFollowsLabel.text = Gat.Text.FOLLOWINGS_TITLE.localized()
        self.editTitleLabel.text = Gat.Text.UserProfile.EDIT_TITLE.localized()
        self.event()
        self.aboutLabel.numberOfLines = 3
        self.aboutLabel.delegate = self
    }
    
    //MARK: - UI
    func setupUI() {
        self.layoutIfNeeded()
        self.editView.cornerRadius(radius: self.editView.frame.height / 2.0)
        self.controller?.userPrivate
            .asObservable()
            .subscribe(onNext: { [weak self] (user) in
                if let profile = user.profile {
                    self?.profileImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId)), placeholderImage: DEFAULT_USER_ICON)
                }
                self?.profileAddressLabel.text = Gat.Text.EditUser.ADDRESS_TITLE.localized() + ": \(user.profile?.address ?? "")"
                self?.setupAbout(user.profile?.about ?? "")

                self?.setupImage()
                self?.controller?.backgroundImage.isHidden = true
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupAbout(_ about: String) {
        guard !about.isEmpty else { return }
        self.aboutLabel.text = about
        self.aboutLabel.collapsed = true
        self.aboutLabel.shouldCollapse = true
        self.aboutLabel.collapsedAttributedLink = NSAttributedString(string: Gat.Text.BookDetail.MORE_TITLE.localized(), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
        self.aboutLabel.expandedAttributedLink = NSAttributedString.init(string: Gat.Text.LESS_TITLE.localized(), attributes:  [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
    }
    
    func setupImage() {
        self.layoutIfNeeded()
//        self.profileImageView.layer.borderColor = #colorLiteral(red: 0.8117647059, green: 0.9333333333, blue: 1, alpha: 1)
//        self.profileImageView.layer.borderWidth = 1.5
        self.profileImageView.circleCorner()
    }
    
    func changeFrame(progress: CGFloat) {
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.editView
            .rx
            .tapGesture()
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.controller?.performSegue(withIdentifier: Gat.Segue.openEditUserInfo, sender: nil)
            })
            .disposed(by: self.disposeBag)
        
        self.followersView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.controller?.performSegue(withIdentifier: FollowViewController.segueIdentifier, sender: FollowViewController.FollowType.follower)
        }).disposed(by: self.disposeBag)
        
        self.followingsView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.controller?.performSegue(withIdentifier: FollowViewController.segueIdentifier, sender: FollowViewController.FollowType.following)
        }).disposed(by: self.disposeBag)
    }
}

extension ProfileDetailView: ExpandableLabelDelegate {
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
