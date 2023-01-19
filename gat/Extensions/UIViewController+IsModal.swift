//
//  UIViewController+IsModal.swift
//  gat
//
//  Created by HungTran on 5/24/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension UIViewController {
    func isModal() -> Bool {
        if let navigationController = self.navigationController{
            if navigationController.viewControllers.first != self{
                return false
            }
        }
        if self.presentingViewController != nil {
            return true
        }
        if self.navigationController?.presentingViewController?.presentedViewController == self.navigationController  {
            return true
        }
        if self.tabBarController?.presentingViewController is UITabBarController {
            return true
        }
        return false
    }
}
