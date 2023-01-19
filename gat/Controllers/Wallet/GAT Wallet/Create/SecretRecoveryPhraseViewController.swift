//
//  SecretRecoveryPhraseViewController.swift
//  gat
//
//  Created by jujien on 02/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import BEMCheckBox

class SecretRecoveryPhraseViewController: UIViewController {
    
    class var segueIdentifier: String { "showSecretRecoveryPhrase" }
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardImage: UIImageView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var acceptButton: BEMCheckBox!
    @IBOutlet weak var containerView: UIView!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let enable = BehaviorRelay<Bool>(value: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.view.layoutIfNeeded()
        self.view.applyGradient(colors: [#colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1), #colorLiteral(red: 0.5725490196, green: 0.5921568627, blue: 0.9098039216, alpha: 1)], start: .zero, end: .init(x: 1.0, y: 0.0))
        self.setupCheckbox()
        self.setupEnableView()
        self.setupSecretRecoverPhraseView()
    }
    
    fileprivate func setupCheckbox() {
        self.acceptButton.boxType = .square
        self.acceptButton.tintColor = .white
        self.acceptButton.onFillColor = .white
        self.acceptButton.onCheckColor = #colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1)
        self.acceptButton.onTintColor = .white
        self.acceptButton.delegate = self
    }
    
    fileprivate func setupEnableView() {
        self.enable
            .do(onNext: { value in
                if value {
                    self.forwardImage.image = #imageLiteral(resourceName: "forward")
                } else {
                    self.forwardImage.image = #imageLiteral(resourceName: "forward").withRenderingMode(.alwaysTemplate)
                    self.forwardImage.tintColor = #colorLiteral(red: 0.7019607843, green: 0.7294117647, blue: 0.768627451, alpha: 1)
                }
            })
            .bind(to: self.nextButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSecretRecoverPhraseView() {
        let view = Bundle.main.loadNibNamed(SecretRecoverPhraseView.className, owner: self)?.first as! SecretRecoverPhraseView
        self.view.layoutIfNeeded()
        view.frame = self.containerView.bounds
        self.containerView.addSubview(view)
        self.containerView.cornerRadius = 16
        self.containerView.borderWidth = 1.5
        self.containerView.borderColor = #colorLiteral(red: 0.9215686275, green: 0.9294117647, blue: 0.937254902, alpha: 1)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap
            .bind { _ in
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: self.disposeBag)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SecretRecoveryPhraseViewController: BEMCheckBoxDelegate {
    func didTap(_ checkBox: BEMCheckBox) {
        self.enable.accept(checkBox.on)
    }
}
