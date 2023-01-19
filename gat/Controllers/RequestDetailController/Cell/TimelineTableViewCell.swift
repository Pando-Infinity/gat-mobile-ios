//
//  TimelineTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 04/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit

class TimelineTableViewCell: UITableViewCell {

    @IBOutlet weak var titleDateLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
