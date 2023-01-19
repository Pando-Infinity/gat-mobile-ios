//
//  TitleHeaderCollectionReusableView.swift
//  gat
//
//  Created by jujien on 05/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit

class TitleHeaderCollectionReusableView: UICollectionReusableView {
    
    class var identifier: String { "header" }
    
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
