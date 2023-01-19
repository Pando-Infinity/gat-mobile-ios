//
//  BookTargetDetailTableViewCell.swift
//  gat
//
//  Created by macOS on 8/21/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit

class BookTargetDetailTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgBook:UIImageView!
    @IBOutlet weak var lbNameBook:UILabel!
    @IBOutlet weak var lbNameAuthor:UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
    }
    
    func setupUI(){
        self.cornerRadius()
    }
    
    func cornerRadius(){
        self.imgBook.cornerRadius = 4.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
}
