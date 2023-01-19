//
//  ScanCollectionViewCell.swift
//  gat
//
//  Created by jujien on 12/31/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class ScanCollectionViewCell: UICollectionViewCell {
    class var identifier: String { return "scanbarCell" }
    
    override var reuseIdentifier: String? { return "" }
    
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.gradientView.applyGradient(colors: [UIColor.clear, #colorLiteral(red: 0.4745098039, green: 0.7215686275, blue: 0.8509803922, alpha: 1)], locations: [0.0, 0.25, 0.35, 1.0], start: .zero, end: .init(x: 1.0, y: 0.0))
        let gradient = self.layer.sublayers?.first(where: { $0.isKind(of: CAGradientLayer.self) })
        if #available(iOS 11.0, *) {
            gradient?.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            gradient?.masksToBounds = true
            gradient?.cornerRadius = 4.0
        } else {
            let shape = CAShapeLayer()
            shape.bounds = self.gradientView.frame
            shape.position = self.gradientView.center
            shape.path = UIBezierPath(roundedRect: self.gradientView.bounds, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: CGSize(width: 4.0, height: 4.0)).cgPath
            self.gradientView.layer.mask = shape 
        }
        
        let text = Gat.Text.Gatup.SCAN_GATUP.localized()
        
        if let index = text.firstIndex(of: "\n") {
            let attributed = NSMutableAttributedString(string: String(text[text.startIndex..<index]), attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)])
            attributed.append(.init(string: String(text[index..<text.endIndex]), attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)]))
            self.titleLabel.attributedText = attributed
        } else {
            self.titleLabel.text = text
        }
        
        self.bringSubviewToFront(self.titleLabel)
        
        self.contentView.cornerRadius(radius: 4.0)
        self.dropShadow(offset: .init(width: 2.0, height: 2.0), radius: 4.0, opacity: 0.4, color: UIColor.black.withAlphaComponent(0.4))
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {} else {
            attributes.frame.size = .init(width: UIScreen.main.bounds.width - 32.0, height: 88.0)
        }
        return attributes
    }
}
