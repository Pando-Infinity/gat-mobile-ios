//
//  SuccessWalletViewController.swift
//  gat
//
//  Created by jujien on 12/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class SuccessWalletViewController: UIViewController {
    
    class var segueIdentifier: String { "showSuccess" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var viewWalletButton: UIButton!
    
    fileprivate let disposeBag = DisposeBag()
    let type = BehaviorRelay(value: `Type`.create)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.type.map { type in
            switch type {
            case `Type`.create: return "Your walle is ready"
            case `Type`.connect: return "Connect wallet successfully!"
            }
        }
        .bind(to: self.titleLabel.rx.text)
        .disposed(by: self.disposeBag)
        
        self.type.map { type in
            switch type {
            case `Type`.create:
                let text = "You have successfully created your new wallet. Remember to keep your Secret Recovery Phrase safe. It's your responsibility!"
                let attrs = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 16.0), .foregroundColor: UIColor.white])
                attrs.addAttributes([.font: UIFont.systemFont(ofSize: 16.0, weight: .semibold)], range: (text as NSString).range(of: "Secret Recovery Phrase"))
                return attrs
            case `Type`.connect:
                return NSAttributedString(string: "You have successfully connect your existing wallet with GAT mobile app. ", attributes: [.font: UIFont.systemFont(ofSize: 16.0), .foregroundColor: UIColor.white])
            }
        }
        .bind(to: self.descriptionLabel.rx.attributedText)
        .disposed(by: self.disposeBag)
        
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.viewWalletButton.rx.tap.bind { _ in
            guard let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: WalletViewController.self)}) else { return }
            self.navigationController?.popToViewController(vc, animated: true)
        }
        .disposed(by: self.disposeBag)
    }

}

extension SuccessWalletViewController {
    enum `Type` {
        case create
        case connect
    }
}
