//
//  CategoryCollectionViewCell.swift
//  gat
//
//  Created by HungTran on 3/6/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseAnalytics

class CategoryCollectionViewCell: UICollectionViewCell {
    //MARK: - UI Properties
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var checked: UIImageView!
    @IBOutlet weak var overlay: UIView!
    @IBOutlet weak var imageFrame: UIImageView!
    
    //MARK: - ViewState
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    func setup(category: Category, isSelected: Bool = false) {
        self.title.text = category.title
        self.image.image = UIImage(named: category.image)
        self.imageFrame.isHidden = !isSelected
        self.overlay.isHidden = !isSelected
        self.checked.isHidden = !isSelected
    }
}
