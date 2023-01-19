//
//  SortByTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 09/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit

class SortByTableViewCell: UITableViewCell {

    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var sortTitleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setup(title: String, active: Bool) {
        self.checkImage.isHidden = !active
        self.sortTitleLabel.text = title
    }
}
