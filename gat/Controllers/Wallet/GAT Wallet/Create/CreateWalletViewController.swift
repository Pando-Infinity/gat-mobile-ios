//
//  CreateWalletViewController.swift
//  gat
//
//  Created by jujien on 01/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//
import PanWalletSDK
import UIKit
import RxSwift

class CreateWalletViewController: UIViewController {
    class var segueIdentifier: String { "showCreateWallet" }

    @IBOutlet weak var createWalletButton: UIButton!
    @IBOutlet weak var connectPanWalletButton: UIButton!
    @IBOutlet weak var termAndConditionLabel: UILabel!
    @IBOutlet weak var importWalletButton: UIButton!
    
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createWalletButton.setTitle("CREATE_NEW_WALLER".localized(), for: .normal)
        self.connectPanWalletButton.setTitle("CONNECT_PANWALLET".localized(), for: .normal)
        self.importWalletButton.setTitle("IMPORT_WALLET".localized(), for: .normal)
        
        let attrs = NSMutableAttributedString(string: "AGREE_TERM_AND_CONDITION".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular), .foregroundColor: #colorLiteral(red: 0.5019607843, green: 0.5490196078, blue: 0.6117647059, alpha: 1)])
        let range = ("AGREE_TERM_AND_CONDITION".localized() as NSString).range(of: "TERM_AND_CONDITIONS".localized())
        attrs.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.5019607843, green: 0.5490196078, blue: 0.6117647059, alpha: 1)], range: range)
        
        self.termAndConditionLabel.attributedText = attrs
        
        self.connectPanWalletButton.rx.tap.bind { _ in
            do {
                try PanWalletManager.shared.connect(chain: .solana)
            } catch {
                AlertCustomViewController.showAlert(title: "Error", message: "PanWallet not downloaded", actions: [.init(titleLabel: "OK")], in: self)
            }
        }
        .disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(.init("panwallet"))
            .compactMap { $0.object as? PanResponse }
            .filter { $0.connectType == .connect }
            .bind { results in
                if results.code == 200 {
                    NotificationCenter.default.post(name: .init("wallet_success"), object: nil)
                } else {
                    print("error")
                }
            }
            .disposed(by: self.disposeBag)
        
    }
    

}
