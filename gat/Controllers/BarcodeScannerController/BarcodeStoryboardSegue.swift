//
//  BarcodeStoryboardSegue.swift
//  gat
//
//  Created by Vũ Kiên on 26/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit

class BarcodeStoryboardSegue: UIStoryboardSegue {
    override func perform() {
        if let fromVC = self.source as? BarcodeScannerController {
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
        } else if let fromVC = self.source as? JoinBarcodeViewController {
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
    
    fileprivate func setup(from: BarcodeScannerController, to: UIViewController) {
        to.view.frame = from.containerView.bounds
        to.didMove(toParent: from)
        from.addChild(to)
        from.containerView.addSubview(to.view)
    }
    
    fileprivate func setup(from: JoinBarcodeViewController, to: UIViewController) {
        to.view.frame = from.containerView.bounds
        to.didMove(toParent: from)
        from.addChild(to)
        from.containerView.addSubview(to.view)
    }
}
