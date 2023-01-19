//
//  GATWalletStoryboardSegue.swift
//  gat
//
//  Created by jujien on 01/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit

class GATWalletStoryboardSegue: UIStoryboardSegue {
    override func perform() {
        guard let fromVC = self.source as? GATWalletViewController else {
            return
        }
        fromVC.childViewController?.willMove(toParent: nil)
        fromVC.childViewController?.removeFromParent()
        fromVC.childViewController?.view.removeFromSuperview()
        
        let toVC = self.destination
        toVC.view.frame = fromVC.view.bounds
        toVC.didMove(toParent: fromVC)
        fromVC.addChild(toVC)
        fromVC.view.addSubview(toVC.view)
        fromVC.childViewController = toVC
    }
}
