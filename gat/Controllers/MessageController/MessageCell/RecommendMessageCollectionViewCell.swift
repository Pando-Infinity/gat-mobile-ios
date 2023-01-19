//
//  RecommendMessageCollectionViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 21/08/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit

class RecommendMessageCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String {
        return "recommedMessageCell"
    }
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layoutIfNeeded()
        self.cornerRadius(radius: self.bounds.height / 2.0)
    }
}

extension RecommendMessageCollectionViewCell {
    class func size(message: String, collectionView: UICollectionView) -> CGSize {
        let label = UILabel()
        label.text = message
        label.font = .systemFont(ofSize: 12)
        label.sizeToFit()
        label.numberOfLines = 1
        let size = label.sizeThatFits(.init(width: collectionView.bounds.width, height: 35.0))
        return .init(width: size.width + 16.0, height: 27.0)
    }
}
