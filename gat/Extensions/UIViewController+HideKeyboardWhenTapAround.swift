//
//  UIViewController+HideKeyboardWhenTapAround.swift
//  gat
//
//  Created by HungTran on 5/19/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

// Put this piece of code anywhere you like
extension UIViewController {
    
    /**Tự động ẩn Keyboard khi người dùng Tap ra bên ngoài Keyboard. 
     Riêng đối với trường hợp UIMapViewController.
     Buộc phải thêm 1 UIView phụ phủ ra ngoài thì mới nhận được Event này.*/
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func topMostViewController() -> UIViewController {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        if let tab = self as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}
