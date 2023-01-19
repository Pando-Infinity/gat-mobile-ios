//
//  SearchStoryboardSegue.swift
//  gat
//
//  Created by Vũ Kiên on 03/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit

class SearchStoryboardSegue: UIStoryboardSegue {
    override func perform() {
        if let fromVC = self.source as? SearchSuggestionViewController {
            fromVC.previousVC?.willMove(toParent: nil)
            fromVC.previousVC?.removeFromParent()
            fromVC.previousVC?.view.removeFromSuperview()
            let toVC = self.destination
            if let vc = fromVC.controllers.filter({$0.className == toVC.className}).first {
                self.setup(from: fromVC, to: vc)
            } else {
                fromVC.controllers.append(toVC)
                self.setup(from: fromVC, to: toVC)
            }
        } else if let fromVC = self.source as? SearchViewController {
            fromVC.previousVC?.willMove(toParent: nil)
            fromVC.previousVC?.removeFromParent()
            fromVC.previousVC?.view.removeFromSuperview()
            let toVC = self.destination
            if let vc = fromVC.controllers.filter({$0.className == toVC.className}).first {
                self.setup(from: fromVC, to: vc)
            } else {
                fromVC.controllers.append(toVC)
                self.setup(from: fromVC, to: toVC)
            }
        }
        
    }
    
    fileprivate func setup(from: SearchSuggestionViewController, to: UIViewController) {
        to.view.frame = from.containerView.bounds
        to.didMove(toParent: from)
        from.addChild(to)
        from.containerView.addSubview(to.view)
    }
    
    fileprivate func setup(from: SearchViewController, to: UIViewController) {
        to.view.frame = from.containerView.bounds
        to.didMove(toParent: from)
        from.addChild(to)
        from.containerView.addSubview(to.view)
    }
}
