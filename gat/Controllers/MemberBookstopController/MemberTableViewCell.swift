//
//  MemberTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 16/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit

class MemberTableViewCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var numberBookLabel: UILabel!
    @IBOutlet weak var numberReviewLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupUI(user: UserPublic) {
        self.userImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: user.profile.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        self.nameLabel.text = user.profile.name
        self.addressLabel.text = user.profile.address
        self.layoutIfNeeded()
        self.userImageView.circleCorner()
        self.numberBookLabel.text = "\(user.sharingCount)"
        self.numberReviewLabel.text = "\(user.reviewCount)"
    }

}
