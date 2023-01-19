//
//  Extension+UIView.swift
//  gat
//
//  Created by Vũ Kiên on 15/03/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func cornerRadius(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
    
    func circleCorner() {
        self.cornerRadius(radius: self.frame.height / 2)
    }
    
    func circleCorner(thickness: CGFloat, color: UIColor) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = thickness
        self.cornerRadius(radius: self.frame.height / 2)
    }
    
    func circleCorner(radius: CGFloat, thickness: CGFloat, color: UIColor) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = thickness
        self.cornerRadius(radius: radius)
    }
    
    func applyGradient(colors: [UIColor], locations: [NSNumber]? = nil, start: CGPoint = .zero, end: CGPoint = .init(x: 0.0, y: 1.0)) {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colors.map{ $0.cgColor }
        gradient.locations = locations
        gradient.startPoint = start
        gradient.endPoint = end
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    internal var containsFirstResponder: Bool {
        if isFirstResponder { return true }
        for view in subviews {
            if view.containsFirstResponder { return true }
        }
        return false
    }
}
