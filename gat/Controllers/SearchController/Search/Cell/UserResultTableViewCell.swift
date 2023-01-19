//
//  UserResultTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 16/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit

class UserResultTableViewCell: UITableViewCell {

    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    //@IBOutlet weak var activeView: UIView!
    @IBOutlet weak var numberSharingBookLabel: UILabel!
    @IBOutlet weak var numberReviewBookLabel: UILabel!
    @IBOutlet weak var reviewImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setup(userPublic: UserPublic) {
        self.layoutIfNeeded()
        self.setup(profile: userPublic.profile)
        self.distanceLabel.text = AppConfig.sharedConfig.stringDistance(userPublic.distance)
        self.distanceLabel.isHidden = userPublic.distance < 0
        self.addressLabel.sizeToFit()
        self.numberSharingBookLabel.text = "\(userPublic.sharingCount)"
        self.numberReviewBookLabel.text = "\(userPublic.reviewCount)"
        
        self.numberReviewBookLabel.isHidden = userPublic.profile.userTypeFlag != .normal
        self.reviewImageView.isHidden = userPublic.profile.userTypeFlag != .normal
        
    }
    
    fileprivate  func setup(profile: Profile) {
        self.layoutIfNeeded()
        self.friendImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        self.friendImageView.circleCorner()
        self.nameLabel.text = profile.name
        self.addressLabel.text = profile.address
        self.aboutLabel.text = profile.about
    }

}

extension UserResultTableViewCell {
    class func size(user: UserPublic, in tableView: UITableView) -> CGFloat {
        let address = UILabel()
        address.text = user.profile.address
        address.font = .systemFont(ofSize: 12.0)
        let sizeAddress = address.sizeThatFits(.init(width: tableView.frame.width - 70.0, height: .infinity))
        let about = UILabel()
        about.text = user.profile.about
        about.font = .systemFont(ofSize: 13.0)
        about.numberOfLines = 2
        let sizeAbout = about.sizeThatFits(.init(width: tableView.frame.width - 70.0, height: .infinity))
        return 65.0 + sizeAddress.height + sizeAbout.height
    }
}
