//
//  UserCollectionViewCell.swift
//  Gatbook
//
//  Created by GaT-Kien on 2/21/17.
//  Copyright © 2017 GaT-Kien. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SDWebImage

class UserCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var activeView: UIView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupUser(_ user: UserPublic) {
        self.layoutIfNeeded()
        self.userImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: user.profile.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.userImageView.circleCorner()
        self.nameLabel.text = user.profile.name
        self.setupActiveView(active: user.activeFlag)
    }
    
    fileprivate func setupActiveView(active: Bool) {
        self.layoutIfNeeded()
        self.activeView.layer.borderColor = active ? #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1) : #colorLiteral(red: 0.7607843137, green: 0.7607843137, blue: 0.7607843137, alpha: 1)
        self.activeView.layer.borderWidth = 1.5
        self.activeView.circleCorner()
    }

}
