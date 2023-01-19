//
//  HandleError.swift
//  gat
//
//  Created by Vũ Kiên on 19/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation

class HandleError {
    static let `default` = HandleError()
    
    fileprivate init() {}
    
    func showAlert(with error: Error, action: (() -> Void)? = nil) {
        print(error.localizedDescription)
        guard let topViewController = UIApplication.shared.topMostViewController() else { return }
        guard let error = error as? ServiceError else {
            AlertCustomViewController.showAlert(title: Gat.Text.CommonError.ERROR_ALERT_TITLE.localized(), message: Gat.Text.CommonError.SERVER_ERROR_MESSAGE.localized(), actions: [.init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: action)], in: topViewController)
            return
        }
        var message = error.userInfo?["message"] ?? ""
        var actions: [ActionButton] = []
        if let status = error.status {
            switch status {
            case .badRequest :
                actions.append(.init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: action))
                break
            case .unAuthorized:
                actions.append(.init(titleLabel: Gat.Text.CommonError.LOGIN_ALERT_TITLE.localized(), action: {
                    LogoutService.shared.logout()
                }))
                break
            case .conflict:
                actions.append(.init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: action))
                break
            case .internalServerError, .notImplemented, .badGateway, .serviceUnavailable, .gatewayTimeout:
                message = Gat.Text.CommonError.SERVER_ERROR_MESSAGE.localized()
                actions.append(.init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: action))
                break
            default:
                actions.append(.init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: action))
                break
            }
        } else {
            actions.append(.init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: nil))
        }
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.ERROR_ALERT_TITLE.localized(), message: message, actions: actions, in: topViewController)
    }
    
    
    func loginAlert(action: (() -> Void)? = nil) {
        guard let topViewController = UIApplication.shared.topMostViewController() else {
            return
        }
        let loginAction = ActionButton(titleLabel: Gat.Text.CommonError.LOGIN_ALERT_TITLE.localized()) {
            LogoutService.shared.logout()
        }
        let skipAction = ActionButton(titleLabel: Gat.Text.CommonError.SKIP_ALERT_TITLE.localized()) {
            action?()
        }
        
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.LOGIN_ALERT_TITLE.localized(), message: Gat.Text.CommonError.LOGIN_ALERT_MESSAGE.localized(), actions: [loginAction, skipAction], in: topViewController)
    }
}
