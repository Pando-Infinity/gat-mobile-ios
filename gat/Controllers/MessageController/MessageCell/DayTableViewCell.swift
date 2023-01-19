//
//  DayTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 24/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit

class DayTableViewCell: UITableViewCell {

    @IBOutlet weak var dayLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setup(day: String) {
        self.dayLabel.text = day
    }

}
