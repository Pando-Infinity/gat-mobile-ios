//
//  HeaderBookstopOrganizationCollectionReusableView.swift
//  gat
//
//  Created by jujien on 7/27/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import SnapKit

class HeaderBookstopOrganizationCollectionReusableView: UICollectionReusableView {
    
    class var identifier: String { "bookstopOrganizationHeader" }
    
    static let HEIGHT: CGFloat = 43.0
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var size: CGSize = .zero
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.font = .systemFont(ofSize: 16.0, weight: .bold)
        self.titleLabel.textColor = #colorLiteral(red: 0, green: 0.1417105794, blue: 0.2883770168, alpha: 1)
        self.backgroundColor = .white
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.size != .zero {
            layoutAttributes.size = self.size
        }
        return layoutAttributes
    }
        
}
