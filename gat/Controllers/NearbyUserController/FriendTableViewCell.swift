//
//  FriendTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 06/03/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import SDWebImage

class FriendTableViewCell: UITableViewCell {

    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var activeView: UIView!
    @IBOutlet weak var sharingBookLabel: UILabel!
    @IBOutlet weak var reviewBookLabel: UILabel!
    @IBOutlet weak var reviewImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setup(user: UserPublic) {
        self.setup(profile: user.profile)
        self.setupActiveView(active: user.activeFlag)
        self.setupDistance(user.distance)
        self.setupBook(of: user)
    }
    
    fileprivate func setup(profile: Profile) {
        self.layoutIfNeeded()
        self.nameLabel.text = profile.name
        self.addressLabel.text = profile.address
        self.friendImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        self.friendImageView.circleCorner()
        self.addressLabel.sizeToFit()
    }
    
    fileprivate func setupActiveView(active: Bool) {
        self.layoutIfNeeded()
        self.activeView.layer.borderColor = active ? #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1) : #colorLiteral(red: 0.7607843137, green: 0.7607843137, blue: 0.7607843137, alpha: 1)
        self.activeView.layer.borderWidth = 1.5
        self.activeView.circleCorner()
    }
    
    fileprivate func setupDistance(_ distance: Double) {
        self.distanceLabel.text = AppConfig.sharedConfig.stringDistance(distance)
        self.distanceLabel.isHidden = distance < 0
    }
    
    fileprivate func setupBook(of user: UserPublic) {
        self.sharingBookLabel.text = "\(user.sharingCount)"
        self.reviewBookLabel.text = "\(user.reviewCount)"
        self.setupActiveView(active: user.activeFlag)
        if user.profile.userTypeFlag == .normal {
            self.reviewBookLabel.isHidden = false
            self.reviewImageView.isHidden = false
        } else {
            self.reviewBookLabel.isHidden = true
            self.reviewImageView.isHidden = true
        }
    }
    
}
