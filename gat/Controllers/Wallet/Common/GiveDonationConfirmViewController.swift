//
//  GiveDonationConfirmViewController.swift
//  gat
//
//  Created by jujien on 08/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class GiveDonationConfirmViewController: UIViewController {
    
    fileprivate let disposeBag = DisposeBag()
    let profile = BehaviorRelay<Profile?>(value: nil)
    let amount = BehaviorRelay<Double?>(value: nil)
    
    fileprivate let giveMoreButton = UIButton()
    fileprivate let viewHistoryButton = UIButton()
    var giveMoreHandler: ((Profile) -> Void)?
    var showTransaction: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            self.dismiss(animated: true)
        }
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.view.backgroundColor = .white
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        self.view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(24)
            make.trailing.equalToSuperview().inset(16)
        }
        
        Observable.combineLatest(self.profile.compactMap { $0 }, self.amount.compactMap { $0 })
            .map { profile, amount in
            
                let text = "You just gave \(Int(amount)) GAT to \(profile.name) to appreciate their work."
                let attributeText = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)])
                attributeText.addAttributes([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)], range: (text as NSString).range(of: "\(Int(amount)) GAT"))
                attributeText.addAttributes([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)], range: (text as NSString).range(of: profile.name))
                
                return attributeText
            }
            .bind(to: titleLabel.rx.attributedText)
            .disposed(by: self.disposeBag)
        
        self.giveMoreButton.setAttributedTitle(.init(string: "Give more GAT", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)]), for: .normal)
        self.giveMoreButton.backgroundColor = #colorLiteral(red: 0.8941176471, green: 0.9490196078, blue: 0.9803921569, alpha: 1)
        self.giveMoreButton.cornerRadius = 8
        self.view.addSubview(self.giveMoreButton)
        
        self.viewHistoryButton.setAttributedTitle(.init(string: "View transaction", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: UIColor.white]), for: .normal)
        self.viewHistoryButton.backgroundColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        self.viewHistoryButton.cornerRadius = 8
        self.view.addSubview(self.viewHistoryButton)
        
        self.giveMoreButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalTo(self.view.snp_bottomMargin).inset(8)
            make.height.equalTo(40)
        }
        self.viewHistoryButton.snp.makeConstraints { make in
            make.leading.equalTo(self.giveMoreButton.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(self.giveMoreButton.snp.top)
            make.height.equalTo(self.giveMoreButton.snp.height)
            make.width.equalTo(self.giveMoreButton.snp.width)
        }
        
        
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.giveMoreButton.rx.tap.bind { _ in
            self.dismiss(animated: true) {
                if let profile = self.profile.value {
                    self.giveMoreHandler?(profile)
                }
            }
        }
        .disposed(by: self.disposeBag)
        
        self.viewHistoryButton.rx.tap.bind { _ in
            self.dismiss(animated: true) {
                self.showTransaction?()
            }
        }
        .disposed(by: self.disposeBag)
    }

}
