//
//  UIView+Shadow.swift
//  gat
//
//  Created by HungTran on 4/15/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func dropShadow(offset: CGSize = CGSize(width: 0.5, height: 0.4), radius: CGFloat = 10.0, opacity: Float = 0.5, color: UIColor = UIColor.darkGray) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
    }
}
