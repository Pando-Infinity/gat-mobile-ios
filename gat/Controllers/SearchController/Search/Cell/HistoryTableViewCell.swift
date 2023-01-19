//
//  HistoryTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 15/03/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import SDWebImage

class HistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var historyView: UIView!
    @IBOutlet weak var historyImageView: UIImageView!
    @IBOutlet weak var historyLabel: UILabel!
    @IBOutlet weak var history1Label: UILabel!
    @IBOutlet weak var historyImageContraint: NSLayoutConstraint!
    @IBOutlet weak var historyContraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.historyImageView.image = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.historyImageView.image = nil
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.historyView.circleCorner()
    }
    
    func setContraint( _ contraint: NSLayoutConstraint, constant: CGFloat) {
        contraint.constant = constant
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    ///set up cell khi hien thi lich su
    func setupHistory(label: String, index: Int) {
        //an label 1
        self.history1Label.isHidden = true
        
        //show background image
        self.historyView.isHidden = false
        
        //set image
        self.layoutIfNeeded()
        self.setContraint(self.historyImageContraint, constant: 0)
        self.historyImageView.cornerRadius(radius: 0)
        switch index {
        case 0:
            self.historyImageView.image = BOOK_PLACEHOLDER_ICON
            break
        case 1:
            self.historyImageView.image = AUTHOR_PLACEHOLDER_ICON
            break
        case 2:
            self.historyImageView.image = USER_PLACEHOLDER_ICON
            break
        default:
            break
        }
        
        //dua historylabel ra giua
        self.setContraint(self.historyContraint, constant: 0.0)
        self.setContraint(self.historyContraint, constant: (1.0 - self.historyContraint.multiplier) * (self.frame.height) / 2.0)
        
        //set title
        self.historyLabel.text = label
        self.historyLabel.textColor = HISTORY_TITLE_COLOR
        self.historyLabel.font = UIFont.systemFont(ofSize: 13.0)
    }
    
    ///set up cell khi hien thi ten ban be
    func setup(user: User) {
        //hidden background image
        self.historyView.isHidden = true
        
        self.layoutIfNeeded()
        //set image
        self.setContraint(self.historyImageContraint, constant: 0.0)
        self.setContraint(self.historyImageContraint, constant: 0.2*self.frame.height)
        self.historyImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: user.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        self.layoutIfNeeded()
        self.historyImageView.circleCorner()
        
        self.setContraint(self.historyContraint, constant: 0.0)
        //set title
        self.historyLabel.text = user.name
        self.historyLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.historyLabel.tintColor = .black
        
        self.history1Label.isHidden = false
        self.history1Label.text = user.address
        self.sizeToFit()
    }
    
}
