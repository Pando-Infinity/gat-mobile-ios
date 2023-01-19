//
//  ItemOptionFilterTableViewCell.swift
//  gat
//
//  Created by jujien on 2/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit

class ItemOptionFilterTableViewCell: UITableViewCell {
    
    class var identifier: String { return "itemCell" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
