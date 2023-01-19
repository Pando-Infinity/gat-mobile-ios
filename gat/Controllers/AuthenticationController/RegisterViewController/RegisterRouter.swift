//
//  RegisterRouter.swift
//  gat
//
//  Created by jujien on 5/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit

protocol RegisterRouter {
    var viewController: UIViewController? { get }
    
    func gotoHome()
    
    func showAlertError(_ error: Error)
}

extension RegisterRouter {
    func gotoHome() {
        let window = self.viewController?.view.window
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: TabBarController.className)
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
    }
    
    func showAlertError(_ error: Error) {
        HandleError.default.showAlert(with: error)
    }
}

struct SimpleRegisterRouter: RegisterRouter {
    weak var viewController: UIViewController?
}

