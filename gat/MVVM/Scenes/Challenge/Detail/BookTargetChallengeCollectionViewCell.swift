//
//  BookTargetChallengeCollectionViewCell.swift
//  gat
//
//  Created by macOS on 8/24/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit

class BookTargetChallengeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imgBook:UIImageView!
    @IBOutlet weak var lbNumberBookRest:UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.imgBook.contentMode = .scaleToFill
        self.imgBook.cornerRadius(radius: 4.0)
        self.lbNumberBookRest.isHidden = true
    }

}
