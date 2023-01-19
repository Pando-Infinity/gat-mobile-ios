//
//  FailGiveDonateViewController.swift
//  gat
//
//  Created by jujien on 08/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit

class FailGiveDonateViewController: UIViewController {
    
    var depositHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            self.dismiss(animated: true)
        }
        self.view.backgroundColor = .white
        let titleLabel = UILabel()
        titleLabel.text = "You don't have enough GAT in your app wallet to give."
        titleLabel.numberOfLines = 2
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
        self.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(16)
        }
        
        let button = UIButton()
        button.setAttributedTitle(.init(string: "Deposit GAT", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: UIColor.white]), for: .normal)
        button.backgroundColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        button.cornerRadius = 8
        self.view.addSubview(button)
        button.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.snp_bottomMargin).inset(8)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        button.addTarget(self, action: #selector(depositAction(sender:)), for: .touchUpInside)
    }
    
    @objc func depositAction(sender: UIButton) {
        self.dismiss(animated: true) {
            self.depositHandler?()
        }
    }
}
