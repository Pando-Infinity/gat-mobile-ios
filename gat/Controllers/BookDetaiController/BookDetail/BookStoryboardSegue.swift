//
//  BookStoryboardSegue.swift
//  gat
//
//  Created by Vũ Kiên on 15/11/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit

class BookStoryboardSegue: UIStoryboardSegue {
    override func perform() {
        guard let fromVC = self.source as? BookDetailViewController else {
            return
        }
        fromVC.previousController?.willMove(toParent: nil)
        fromVC.previousController?.removeFromParent()
        fromVC.previousController?.view.removeFromSuperview()
        
        let toVC = self.destination
        if let controller = fromVC.controllers.filter({$0.className == toVC.className}).first {
            self.animateProfileView(from: fromVC, to: controller)
            self.addController(from: fromVC, to: controller)
        } else {
            fromVC.controllers.append(toVC)
            self.animateProfileView(from: fromVC, to: toVC)
            self.addController(from: fromVC, to: toVC)
        }
    }
    
    fileprivate func addController(from: BookDetailViewController, to: UIViewController) {
        to.view.frame = from.containerView.bounds
        to.didMove(toParent: from)
        from.addChild(to)
        from.containerView.addSubview(to.view)
        from.previousController = to
    }
    
    fileprivate func animateProfileView(from: BookDetailViewController, to: UIViewController) {
        var height: CGFloat = 0.0
        if let vc = to as? PriceViewController {
            height = vc.height
        } else if let vc = to as? BookDetailContainerController {
            height = vc.height
        }
        if height == 0.0 {
            height = from.heightDetailContainerConstraint.multiplier * from.view.frame.height
        }
        UIView.animate(withDuration: 0.1, animations: {
            from.changeFrameProfileView(height: height)
        })
    }
}
