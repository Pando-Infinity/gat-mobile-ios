//
//  GATWalletViewController.swift
//  gat
//
//  Created by jujien on 01/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class GATWalletViewController: UIViewController {
    class var segueIdentifier: String { "showGATWallet" }
    
    var childViewController: UIViewController?
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefaults.standard.string(forKey: "wallet") == "success" {
            self.performSegue(withIdentifier: GATWalletDetailViewController.segueIdentifier, sender: nil)
        } else {
            self.performSegue(withIdentifier: CreateWalletViewController.segueIdentifier, sender: nil)
        }
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: "wallet_success"))
            .bind { _ in
                UserDefaults.standard.set("success", forKey: "wallet")
                self.performSegue(withIdentifier: GATWalletDetailViewController.segueIdentifier, sender: nil)
            }
            .disposed(by: self.disposeBag)
    }

}
