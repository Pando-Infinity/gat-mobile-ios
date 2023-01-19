//
//  WalletStoryboardSegue.swift
//  gat
//
//  Created by jujien on 01/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit

class WalletStoryboardSegue: UIStoryboardSegue {
    override func perform() {
        guard let fromVC = self.source as? WalletViewController else {
            return
        }
        fromVC.previousController?.willMove(toParent: nil)
        fromVC.previousController?.removeFromParent()
        fromVC.previousController?.view.removeFromSuperview()
        
        let toVC = self.destination
        if let controller = fromVC.controllers.filter({$0.className == toVC.className}).first {
            self.addController(from: fromVC, to: controller)
        } else {
            fromVC.controllers.append(toVC)
            self.addController(from: fromVC, to: toVC)
        }
    }
    
    fileprivate func addController(from: WalletViewController, to: UIViewController) {
        to.view.frame = from.containerView.bounds
        to.didMove(toParent: from)
        from.addChild(to)
        from.containerView.addSubview(to.view)
        from.previousController = to
    }
}
