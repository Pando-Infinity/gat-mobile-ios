//
//  WalletTableViewCell.swift
//  gat
//
//  Created by jujien on 01/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class WalletTableViewCell: UITableViewCell {
    
    @IBOutlet weak var walletContainerView: UIView!
    @IBOutlet weak var inAppWalletTitleLabel: UILabel!
    @IBOutlet weak var inAppWalletValueLable: UILabel!
    @IBOutlet weak var gatWalletTitleLabel: UILabel!
    @IBOutlet weak var gatWalletValueLabel: UILabel!
    @IBOutlet weak var viewWalletLabel: UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    var setupAction: (() -> Void)?
    
    static let identifier = "WalletCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        self.walletContainerView.cornerRadius(radius: 12)
        self.walletContainerView.borderColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        self.walletContainerView.borderWidth = 1
        self.inAppWalletTitleLabel.text = "IN_APP_BALACE".localized()
        self.gatWalletTitleLabel.text = "GAT_WALLET_BALANCE".localized()
        self.viewWalletLabel.text = "VIEW_MY_WALLET".localized()
        self.gatWalletValueLabel.rx.tapGesture()
            .when(.recognized)
            .bind { _ in
                self.setupAction?()
            }
            .disposed(by: self.disposeBag)
    }

}
