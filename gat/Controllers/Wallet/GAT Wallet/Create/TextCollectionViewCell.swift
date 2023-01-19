//
//  TextCollectionViewCell.swift
//  gat
//
//  Created by jujien on 02/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit

class TextCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "textCell" }
    
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
