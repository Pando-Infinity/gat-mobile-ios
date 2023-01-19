//
//  WalletViewController.swift
//  gat
//
//  Created by jujien on 01/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class WalletViewController: UIViewController {
    
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var inAppWalletLabel: UILabel!
    @IBOutlet weak var gatWalletLabel: UILabel!
    @IBOutlet weak var inAppWalletView: UIView!
    @IBOutlet weak var gatWalletView: UIView!
    @IBOutlet weak var selectionLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    
    var currentIndex = BehaviorRelay<Int>(value: 0)
    var controllers: [UIViewController] = []
    var previousController: UIViewController?
    
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.backButton.setTitle("", for: .normal)
        self.inAppWalletLabel.text = "IN_APP_WALLET".localized()
        self.gatWalletLabel.text = "GAT_WALLET".localized()
        self.setupNavigation()
        self.currentIndex.bind { index in
            self.changeSelection(index: index)
            if index == 0 {
                self.selectInApp(value: true)
                self.selectGatWallet(value: false)
                self.performSegue(withIdentifier: InAppWalletViewController.segueIdentifier, sender: nil)
            } else {
                self.selectGatWallet(value: true)
                self.selectInApp(value: false)
                self.performSegue(withIdentifier: GATWalletViewController.segueIdentifier, sender: nil)
            }
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupNavigation() {
        self.view.layoutIfNeeded()
        self.navigationView.applyGradient(colors: [#colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1), #colorLiteral(red: 0.5725490196, green: 0.5921568627, blue: 0.9098039216, alpha: 1)], start: .zero, end: .init(x: 1.0, y: .zero))
    }
    
    fileprivate func changeSelection(index: Int) {
        UIView.animate(withDuration: 0.3) {
            self.selectionLeadingConstraint.constant = CGFloat(index) * self.view.frame.width / 2.0
            self.view.layoutIfNeeded()
        }
    }
    
    fileprivate func selectInApp(value: Bool) {
        self.inAppWalletLabel.textColor = value ? #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1) : #colorLiteral(red: 0.5019607843, green: 0.5490196078, blue: 0.6117647059, alpha: 1)
    }
    
    fileprivate func selectGatWallet(value: Bool) {
        self.gatWalletLabel.textColor = value ? #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1) : #colorLiteral(red: 0.5019607843, green: 0.5490196078, blue: 0.6117647059, alpha: 1)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.selectionEvent()
    }
    
    fileprivate func selectionEvent() {
        Observable.of(
            self.inAppWalletView.rx.tapGesture().when(.recognized).asObservable(),
            self.gatWalletView.rx.tapGesture().when(.recognized).asObservable()
        )
        .merge()
        .bind { gesture in
            self.selectInApp(value: gesture.view === self.inAppWalletView)
            self.selectGatWallet(value: gesture.view === self.gatWalletView)
            self.changeSelection(index: gesture.view === self.inAppWalletView ? 0 : 1)
            if gesture.view === self.inAppWalletView {
                self.performSegue(withIdentifier: InAppWalletViewController.segueIdentifier, sender: nil)
            } else {
                self.performSegue(withIdentifier: GATWalletViewController.segueIdentifier, sender: nil)
            }
        }
        .disposed(by: self.disposeBag)
        
        
        self.inAppWalletView.rx
            .tapGesture().when(.recognized)
            .bind { [weak self] _ in
                self?.changeSelection(index: 0)
                self?.selectInApp(value: true)
                self?.selectGatWallet(value: false)
            }
            .disposed(by: self.disposeBag)
    }
    
    
    
    
    fileprivate func backEvent() {
        self.backButton.rx
            .tap
            .bind { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: self.disposeBag)
            
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}
