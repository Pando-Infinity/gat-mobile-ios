//
//  HeaderReadingListCollectionReusableView.swift
//  gat
//
//  Created by jujien on 1/17/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit

class HeaderReadingListCollectionReusableView: UICollectionReusableView {
    class var identifier: String { return "header" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seperateView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
}
