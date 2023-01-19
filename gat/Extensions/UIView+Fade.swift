//
//  UIView+Fade.swift
//  gat
//
//  Created by HungTran on 4/21/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func fadeIn(withDuration duration: TimeInterval = 1.0, to: CGFloat) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = to
        })
    }
    
    func fadeOut(withDuration duration: TimeInterval = 1.0, to: CGFloat) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = to
        })
    }
}
