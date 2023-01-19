//
//  BookStopStoryboardSegue.swift
//  gat
//
//  Created by Vũ Kiên on 28/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit

class BookStopStoryboardSegue: UIStoryboardSegue {
    override func perform() {
        guard let fromVC = self.source as? BookStopViewController else {
            return
        }
        let toVC = self.destination
        fromVC.view.layoutIfNeeded()
        
        if let previousVC = fromVC.previousVC {
            previousVC.willMove(toParent: nil)
            previousVC.view.removeFromSuperview()
            previousVC.removeFromParent()
        }
        
        if let indexVC = fromVC.controllers.filter({$0.className == toVC.className}).first {
            self.animateProfileView(from: fromVC, to: indexVC)
            self.setup(to: indexVC, from: fromVC)
        } else {
            fromVC.controllers.append(toVC)
            self.animateProfileView(from: fromVC, to: toVC)
            self.setup(to: toVC, from: fromVC)
        }
    }
    
    fileprivate func setup(to: UIViewController, from: BookStopViewController) {
        to.view.frame = from.containerView.bounds
        to.didMove(toParent: from)
        from.containerView.addSubview(to.view)
        from.addChild(to)
        from.previousVC = to
    }
    
    fileprivate func animateProfileView(from: BookStopViewController, to: UIViewController) {
        var height: CGFloat = 0.0
        if let vc = to as? BookCaseViewController {
            height = vc.height
        } else if let vc = to as? BookSpaceViewController {
            height = vc.height
        }
        if height == 0.0 {
            height = from.backgroundHeightConstraint.multiplier * from.view.frame.height
        }
        UIView.animate(withDuration: 0.1, animations: {
            from.changeFrameProfileView(height: height)
        })
    }
}
