//
//  File.swift
//  gat
//
//  Created by jujien on 5/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation

protocol LoginRouter {
    var viewController: UIViewController? { get }
    
    func gotoHome()
    
    func showAlertError(_ error: Error)
}

extension LoginRouter {
    func gotoHome() {
        let window = self.viewController?.view.window
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: TabBarController.className)
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
    }
    
    func showAlertError(_ error: Error) {
        guard let error = error as? ServiceError, error.code != -1 else { return }
        HandleError.default.showAlert(with: error)
    }
}

struct SimpleLoginRouter: LoginRouter {
    weak var viewController: UIViewController?
}
