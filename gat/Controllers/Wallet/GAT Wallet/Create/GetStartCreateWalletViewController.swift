//
//  GetStartCreateWalletViewController.swift
//  gat
//
//  Created by jujien on 01/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class GetStartCreateWalletViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var getStartButton: UIButton!
    @IBOutlet weak var secueLabel: UILabel!
    @IBOutlet weak var secueDescriptionLabel: UILabel!
    
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    fileprivate func setupUI() {
        self.secueLabel.text = "SECUE_YOUR_WALLET".localized()
        let attrs = NSMutableAttributedString(string: "SECUE_DESCRIPTION".localized(), attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .regular), .foregroundColor: UIColor.white])
        attrs.addAttributes([.font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: UIColor.white], range: ("SECUE_DESCRIPTION".localized() as NSString).range(of: "SECRET_RECOVERY_PHRASE".localized()))
        self.secueDescriptionLabel.attributedText = attrs
        self.getStartButton.setTitle("GET_START".localized(), for: .normal)
    }
    
    fileprivate func event() {
        self.backButton
            .rx.tap.bind { _ in
                self.navigationController?.popViewController(animated: true)
            }.disposed(by: self.disposeBag)
    }


}
