//
//  MessageYouTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 22/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit

class MessageYouTableViewCell: UITableViewCell {

    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupUI(message: Message) {
        self.layoutIfNeeded()
        self.messageLabel.text = message.content
        self.messageLabel.sizeToFit()
        self.messageView.cornerRadius(radius: 15.0)
    }

}
