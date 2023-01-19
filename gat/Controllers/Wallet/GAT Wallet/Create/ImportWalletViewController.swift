//
//  ImportWalletViewController.swift
//  gat
//
//  Created by jujien on 12/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class ImportWalletViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var secretLabel: UILabel!
    @IBOutlet weak var secretView: UIView!
    @IBOutlet weak var privateLabel: UILabel!
    @IBOutlet weak var privateView: UIView!
    @IBOutlet weak var segmentView: UIView!
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var termAndPolicyLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var forwardImageView: UIImageView!
    @IBOutlet weak var segmentLeadingConstraint: NSLayoutConstraint!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let selectedTab = BehaviorRelay<Tab>(value: .recovery)
    fileprivate let recovery = BehaviorRelay<String>(value: "")
    fileprivate let privateKey = BehaviorRelay<String>(value: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }

    // MARK: - UI
    fileprivate func setupUI() {
        self.backButton.setTitle("", for: .normal)
        self.view.layoutIfNeeded()
        self.view.applyGradient(colors: [#colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1), #colorLiteral(red: 0.5725490196, green: 0.5921568627, blue: 0.9098039216, alpha: 1)], start: .zero, end: .init(x: 1.0, y: 0.0))
        self.setupTab()
        self.setupSegment()
        self.setupPlaceholder()
        self.setupTextView()
        self.setupNext()
        self.setupTermAndPolicy()
    }
    
    fileprivate func setupTab() {
        self.selectedTab.map { tab in
            switch tab {
            case Tab.recovery:
                return NSAttributedString(string: "Secret Recovery Phrase", attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .medium), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)])
            case Tab.private: return NSAttributedString(string: "Secret Recovery Phrase", attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.5019607843, green: 0.5490196078, blue: 0.6117647059, alpha: 1)])
            }
        }
        .bind(to: self.secretLabel.rx.attributedText)
        .disposed(by: self.disposeBag)
        
        self.selectedTab.map { tab in
            switch tab {
            case Tab.private: return NSAttributedString(string: "Private Key", attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .medium), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)])
            case Tab.recovery: return NSAttributedString(string: "Private key", attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.5019607843, green: 0.5490196078, blue: 0.6117647059, alpha: 1)])
            }
        }
        .bind(to: self.privateLabel.rx.attributedText)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSegment() {
        self.selectedTab.map { tab in
            switch tab {
            case Tab.recovery: return 8.0
            case Tab.private: return 24.0 + self.segmentView.frame.width
            }
        }
        .bind(onNext: { value in
            UIView.animate(withDuration: 0.3) {
                self.segmentLeadingConstraint.constant = value
                self.view.layoutIfNeeded()
            }
        })
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupPlaceholder() {
        Observable
            .combineLatest(self.recovery.asObservable(), self.privateKey.asObservable(), self.selectedTab.asObservable())
            .map { recovery, privateKey, tab in
                switch tab {
                case Tab.recovery: return recovery.isEmpty ? "Enter your Secret Recovery Phrase here. It contains 12, 15, 18, 21 or 24 words." : ""
                case Tab.private: return privateKey.isEmpty ? "Enter your Private Key here. It contains 64 alphanumeric characters. " : ""
                }
            }
            .bind(to: self.placeholderLabel.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTextView() {
        self.textView.backgroundColor = .white
        self.selectedTab.map { tab in
            switch tab {
            case Tab.recovery: return self.recovery.value
            case Tab.private: return self.privateKey.value
            }
        }
        .bind(to: self.textView.rx.text)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupNext() {
        Observable.combineLatest(self.selectedTab, self.recovery.asObservable(), self.privateKey.asObservable())
            .map { tab, recovery, privateKey in
                switch tab {
                case Tab.recovery: return !recovery.isEmpty
                case Tab.private: return !privateKey.isEmpty
                }
            }
            .do(onNext: { value in
                if value {
                    self.forwardImageView.image = #imageLiteral(resourceName: "forward")
                } else {
                    self.forwardImageView.image = #imageLiteral(resourceName: "forward").withRenderingMode(.alwaysTemplate)
                    self.forwardImageView.tintColor = #colorLiteral(red: 0.7019607843, green: 0.7294117647, blue: 0.768627451, alpha: 1)
                }
            })
            .bind(to: self.nextButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTermAndPolicy() {
        let attrs = NSMutableAttributedString(string: "AGREE_TERM_AND_CONDITION".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular), .foregroundColor: UIColor.white])
        let range = ("AGREE_TERM_AND_CONDITION".localized() as NSString).range(of: "TERM_AND_CONDITIONS".localized())
        attrs.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: UIColor.white], range: range)
        
        self.termAndPolicyLabel.attributedText = attrs
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.textViewEvent()
        self.selectTabEvent()
        self.endEditingEvent()
        self.nextEvent()
        self.qrEvent()
    }
    
    fileprivate func endEditingEvent() {
        self.view.rx.tapGesture().when(.recognized)
            .bind { _ in
                self.view.endEditing(true)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap
            .bind { _ in
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func textViewEvent() {
        let shared = Observable.combineLatest(self.textView.rx.text.orEmpty.asObservable(), self.selectedTab.asObservable()).share()
        shared.filter { $0.1 == .recovery }
            .map { $0.0 }
            .bind(onNext: self.recovery.accept(_:))
            .disposed(by: self.disposeBag)
        
        shared.filter { $0.1 == .private }
            .map { $0.0 }
            .bind(onNext: self.privateKey.accept(_:))
            .disposed(by: self.disposeBag)
            
    }
    
    fileprivate func selectTabEvent() {
        Observable.of(
            self.secretView.rx.tapGesture().when(.recognized).map { _ in Tab.recovery },
            self.privateView.rx.tapGesture().when(.recognized).map { _ in Tab.private }
        )
        .merge()
        .bind(onNext: self.selectedTab.accept(_:))
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func nextEvent() {
        self.nextButton.rx.tap.bind { _ in
            if UserDefaults.standard.string(forKey: "passcode") != nil && UserDefaults.standard.string(forKey: "passcode") != "" {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "wallet_success"), object: nil)
                self.performSegue(withIdentifier: SuccessWalletViewController.segueIdentifier, sender: nil)
            } else {
                self.performSegue(withIdentifier: PasscodeViewController.segueIdentifier, sender: nil)
            }
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func qrEvent() {
        self.qrButton.rx.tap.bind { _ in
            self.performSegue(withIdentifier: QRScannerViewController.segueIdentifier, sender: nil)
        }
        .disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == QRScannerViewController.segueIdentifier {
            let vc = segue.destination as? QRScannerViewController
            vc?.resultHandler = { value in
                switch self.selectedTab.value {
                case Tab.recovery: self.recovery.accept(value)
                case Tab.private: self.privateKey.accept(value)
                }
                self.textView.text = value 
            }
        }
    }
}

extension ImportWalletViewController {
    fileprivate enum Tab {
        case recovery
        case `private`
    }
}
