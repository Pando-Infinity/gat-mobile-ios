//
//  ImageCollectionViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 28/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { return "imageCollectionCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    
    var isDefaultSize: Bool = true
    
    var size: CGSize = .zero {
        didSet {
            self.isDefaultSize = false
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if !self.isDefaultSize {
            attributes.frame.size = self.size
        }
        return attributes
    }
    
}
