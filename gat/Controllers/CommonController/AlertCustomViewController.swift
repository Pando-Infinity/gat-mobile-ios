//
//  AlertCustomViewController.swift
//  gat
//
//  Created by Vũ Kiên on 26/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct ActionButton {
    var titleLabel: String = ""
    var action: (() -> Void)?
}

class AlertCustomViewController: UIViewController {
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var centerButton1ConstraintHigh: NSLayoutConstraint!
    @IBOutlet weak var centerButton1ConstraintLow: NSLayoutConstraint!
    @IBOutlet weak var widthButton1ConstraintHigh: NSLayoutConstraint!
    @IBOutlet weak var widthButton1ConstraintLow: NSLayoutConstraint!
    
    weak var viewcontroller: UIViewController?
    
    fileprivate let titleAlert = BehaviorRelay<String>(value: "")
    fileprivate let message = BehaviorRelay<String>(value: "")
    fileprivate let atriMessage = BehaviorRelay<NSAttributedString>(value: NSAttributedString())
    fileprivate var actions = BehaviorRelay<[ActionButton]>(value: [])
    public var flag = BehaviorRelay<Int>(value: 1)
    fileprivate let disposeBag = DisposeBag()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.flag.subscribe(onNext: { (fl) in
            if fl == 2 {
                self.setupUI2()
            } else {
                self.setupUI()
            }
            }).disposed(by: disposeBag)
        //self.setupUI()
        self.event()
    }
    
    static func showAlert(title: String, message: String, actions: [ActionButton], in viewcontroller: UIViewController) {
        let storyboard = UIStoryboard(name: Gat.Storyboard.ALERT, bundle: nil)
        let alert = storyboard.instantiateViewController(withIdentifier: Gat.View.ALERT_CUSTOM_CONTROLLER) as! AlertCustomViewController
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overCurrentContext
        alert.titleAlert.accept(title)
        alert.message.accept(message)
        alert.actions.accept(actions)
        alert.viewcontroller = viewcontroller
        
        viewcontroller.view.alpha = 0.5
        viewcontroller.present(alert, animated: true, completion: nil)
    }
    
    static func showAlert2(title: String, message: NSAttributedString, actions: [ActionButton], in viewcontroller: UIViewController) {
        let storyboard = UIStoryboard(name: Gat.Storyboard.ALERT, bundle: nil)
        let alert = storyboard.instantiateViewController(withIdentifier: Gat.View.ALERT_CUSTOM_CONTROLLER) as! AlertCustomViewController
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overCurrentContext
        alert.titleAlert.accept(title)
        alert.atriMessage.accept(message)
        alert.actions.accept(actions)
        alert.viewcontroller = viewcontroller
        alert.flag.accept(2)
        
        viewcontroller.view.alpha = 0.5
        viewcontroller.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.alertView.cornerRadius(radius: 10.0)
        self.titleAlert.asObservable().bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.message.asObservable().bind { [unowned self] (message) in
            self.messageLabel.text = message
            self.messageLabel.sizeToFit()
            }.disposed(by: self.disposeBag)
    }
    
    fileprivate func setupUI2() {
        self.alertView.cornerRadius(radius: 10.0)
        self.titleAlert.asObservable().bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.atriMessage.asObservable().bind { [unowned self] (message) in
            self.messageLabel.attributedText = message
            self.messageLabel.sizeToFit()
            }.disposed(by: self.disposeBag)
        self.button1.backgroundColor = UIColor.white
        self.button1.layer.borderWidth = 1.0
        self.button1.layer.borderColor = UIColor.init(red: 90.0/255.0, green: 164.0/255.0, blue: 204.0/255.0, alpha: 1.0).cgColor
        self.button1.setTitleColor(UIColor.init(red: 90.0/255.0, green: 164.0/255.0, blue: 204.0/255.0, alpha: 1.0), for: .normal)
    }
    
    fileprivate func changedConstraintButton() {
        self.view.layoutIfNeeded()
        self.view.layoutSubviews()
        if self.actions.value.count == 1 {
            self.centerButton1ConstraintHigh.priority = UILayoutPriority.defaultLow
            self.widthButton1ConstraintHigh.priority = UILayoutPriority.defaultLow
            
            self.centerButton1ConstraintLow.priority = UILayoutPriority.defaultHigh
            self.widthButton1ConstraintLow.priority = UILayoutPriority.defaultHigh
        } else {
            self.centerButton1ConstraintHigh.priority = UILayoutPriority.defaultHigh
            self.widthButton1ConstraintHigh.priority = UILayoutPriority.defaultHigh
            
            self.centerButton1ConstraintLow.priority = UILayoutPriority.defaultLow
            self.widthButton1ConstraintLow.priority = UILayoutPriority.defaultLow
        }
        self.view.layoutSubviews()
        self.view.layoutIfNeeded()
    }
    
    fileprivate func setupUIButton() {
        if self.actions.value.count == 1 {
            self.button2.isHidden = true
            self.view.layoutIfNeeded()
            self.alertView.layoutIfNeeded()
            let action = self.actions.value[0]
            self.button1.setTitle(action.titleLabel, for: .normal)
            self.button1.cornerRadius(radius: self.button1.frame.size.height / 2.0)
        } else if self.actions.value.count == 2 {
            self.button2.isHidden = false
            self.view.layoutIfNeeded()
            self.alertView.layoutIfNeeded()
            self.button1.setTitle(actions.value.first!.titleLabel, for: .normal)
            self.button2.setTitle(actions.value.last!.titleLabel, for: .normal)
            self.button1.cornerRadius(radius: self.button1.frame.size.height / 2.0)
            self.button2.cornerRadius(radius: self.button2.frame.size.height / 2.0)
        }
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.actionsChangedEvent()
        self.button1Event()
        self.button2Event()
    }
    
    fileprivate func actionsChangedEvent() {
        self.actions.asObservable().bind { [unowned self] (actions) in
            self.changedConstraintButton()
            self.setupUIButton()
            }.disposed(by: self.disposeBag)
    }
    
    fileprivate func button1Event() {
        self.button1
            .rx
            .controlEvent(.touchUpInside)
            .asObservable()
            .bind { [weak self] (_) in
                if let count = self?.actions.value.count, count >= 1 {
                    self?.viewcontroller?.view.alpha = 1.0
                    self?.dismiss(animated: true, completion: nil)
                    self?.actions.value.first?.action?()
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func button2Event() {
        self.button2
            .rx
            .controlEvent(.touchUpInside)
            .asObservable().bind { [weak self] (_) in
                if let count = self?.actions.value.count, count >= 2 {
                    self?.viewcontroller?.view.alpha = 1.0
                    self?.dismiss(animated: true, completion: nil)
                    self?.actions.value.last?.action?()
                    
                }
            }
            .disposed(by: self.disposeBag)
    }
}
