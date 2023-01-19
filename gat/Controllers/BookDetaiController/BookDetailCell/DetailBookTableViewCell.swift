//
//  DetailBookTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 12/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import ExpandableLabel

class DetailBookTableViewCell: UITableViewCell{
    @IBOutlet weak var descriptionLabel: ExpandableLabel!
    
    weak var dataSource: DetailCommentDataSource?

    func setupUI(description: String) {
        guard !description.isEmpty else {
            return
        }
        self.descriptionLabel.text = description
        self.descriptionLabel.numberOfLines = 3
        if let collapsed = self.dataSource?.showMoreDescription {
            self.descriptionLabel.collapsed = collapsed
        }
        self.descriptionLabel.delegate = self.dataSource?.viewcontroller
        self.descriptionLabel.collapsedAttributedLink = NSAttributedString(string: Gat.Text.BookDetail.MORE_TITLE.localized(), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
    }
}
