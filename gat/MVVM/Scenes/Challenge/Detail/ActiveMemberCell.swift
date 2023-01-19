//
//  ActiveMemberCell.swift
//  gat
//
//  Created by Hung Nguyen on 1/3/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit

class ActiveMemberCell: UICollectionViewCell {
    
    @IBOutlet weak var ivRank: UIImageView!
    @IBOutlet weak var lbRank: UILabel!
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbTarget: UILabel!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setData(_ leaderBoard: LeaderBoard, _ position: Int) {
        lbName.text = leaderBoard.user?.name ?? ""
        ivAvatar.setCircle(imageId: leaderBoard.user?.imageId ?? "")
        lbTarget.text = String(format: "FORMAT_TARGET_BOOK".localized(), leaderBoard.progress)
        
        // Set rank
        lbRank.text = "\(position + 1)"
        switch position {
        case 0:
            ivRank.image = UIImage(named: "ic_star_yellow")
        case 1:
            ivRank.image = UIImage(named: "ic_star_green")
        case 2:
            ivRank.image = UIImage(named: "ic_star_brown")
        default:
            ivRank.image = UIImage(named: "ic_star_gray")
        }
    }
}

