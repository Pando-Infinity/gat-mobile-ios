//
//  BookstopOrganizationRouter.swift
//  gat
//
//  Created by jujien on 8/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit

protocol BookstopOrganizationRouter {
    var viewController: UIViewController? { get }
    
    func showLogin()
    
    func showAlertEdit(bookstop: Bookstop, action: @escaping (RequestBookstopStatus) -> Void)
}

struct SimpleBookstopOrganizationRouter: BookstopOrganizationRouter {
    weak var viewController: UIViewController?
    
    func showLogin() {
        HandleError.default.loginAlert()
    }
    
    func showAlertEdit(bookstop: Bookstop, action: @escaping (RequestBookstopStatus) -> Void) {
        let kind = bookstop.kind as? BookstopKindOrganization
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let status = kind?.status {
            switch status {
            case .accepted:
                let leaveAction = UIAlertAction(title: Gat.Text.BookstopOrganization.LEAVE_TITLE.localized(), style: .default, handler: { (_) in
                    action(.leave)
                })
                alert.addAction(leaveAction)
                break
            case .waitting:
                let cancelAction = UIAlertAction(title: Gat.Text.BookstopOrganization.CANCEL_TITLE.localized(), style: .default, handler: { (_) in
                    action(.leave)
                })
                alert.addAction(cancelAction)
                break
            }
        } else {
            let joinAction = UIAlertAction(title: Gat.Text.BookstopOrganization.JOIN_TITLE.localized(), style: .default, handler: { (_) in
                if bookstop.memberType == .closed {
                    let storyboard = UIStoryboard(name: "Barcode", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: JoinBarcodeViewController.className) as! JoinBarcodeViewController
                    vc.bookstop = bookstop
                    self.viewController?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    action(.join)
                }
            })
            alert.addAction(joinAction)
        }
        let hideAction = UIAlertAction(title: Gat.Text.BookstopOrganization.HIDE_TITLE.localized(), style: .cancel, handler: nil)
        alert.addAction(hideAction)
        self.viewController?.present(alert, animated: true, completion: nil)
    }
}
