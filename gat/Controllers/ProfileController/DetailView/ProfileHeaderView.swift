//
//  ProfileHeaderView.swift
//  gat
//
//  Created by Vũ Kiên on 10/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit

class ProfileHeaderView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    
    func configure(title: String) {
        if let index = title.index(of: Character.init("(")) {
            self.titleLabel.text = title
            let str = title[index..<title.endIndex]
            let attributedText = NSMutableAttributedString(string: title)
            attributedText.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.568627451, green: 0.568627451, blue: 0.568627451, alpha: 1)], range: NSString(string: title).range(of: String(str)))
            self.titleLabel.attributedText = attributedText
        }
    }
    
}
