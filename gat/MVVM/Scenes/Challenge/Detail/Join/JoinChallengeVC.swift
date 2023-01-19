//
//  JoinChallengeVC.swift
//  gat
//
//  Created by Hung Nguyen on 2/15/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum TargetModeId: Int {
    case fixValue = 1
    case setByUser = 2
}

class JoinChallengeVC: BottomPopupViewController {
    

    var height: CGFloat?
    var topCornerRadius: CGFloat?
    var presentDuration: Double?
    var dismissDuration: Double?
    var shouldDismissInteractivelty: Bool?
    
    var minSlider: Float = 0.0
    var maxSlider: Float = 10.0
    var targetNumber: Float = 0.0
    var targetModeId: TargetModeId = TargetModeId.fixValue
    // Time duration to complete this challenge
    var duration: Int = 0
    
    private let stepSlider: Float = 1.0
    
    
//    @IBOutlet weak var bottomBtnStartWhenActiveKeyBoard: NSLayoutConstraint!
    @IBOutlet weak var bottomAchorOfBtnStart: NSLayoutConstraint!
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var tfNumBookTarget:UITextField!
    @IBOutlet weak var lbBook:UILabel!
    @IBOutlet weak var lbSetGoal:UILabel!
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // Bottom popup attribute variables
    // You can override the desired variable to change appearance
    
    override var popupHeight: CGFloat { return height ?? CGFloat(360.0) }
    
    override var popupTopCornerRadius: CGFloat { return topCornerRadius ?? CGFloat(20) }
    
    override var popupPresentDuration: Double { return presentDuration ?? 0.3 }
    
    override var popupDismissDuration: Double { return dismissDuration ?? 0.3 }
    
    override var popupShouldDismissInteractivelty: Bool { return shouldDismissInteractivelty ?? true }
    
    override var popupDimmingViewAlpha: CGFloat { return BottomPopupConstants.kDimmingViewDefaultAlphaValue }
    
    fileprivate let disposeBag = DisposeBag()
    
    fileprivate var keyboardFrame: CGRect = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init View
        initView()
        dismissKeyboardWhenTapAround()
        activeKeyBoard()
        keyboardNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.frame = .init(x: self.view.frame.origin.x, y: self.view.frame.origin.y - self.keyboardFrame.height, width: self.view.frame.width, height: self.view.frame.height)
    }
    
    private func dismissKeyboardWhenTapAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboardTapAround))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboardTapAround() {
//        bottomBtnStartWhenActiveKeyBoard.constant = 24.0
        view.endEditing(true)
    }
    
    private func keyboardNotification(){
        Observable.of(
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification),
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
        ).merge()
            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1)})
            .subscribe(onNext: { (notification, vc) in
                vc.view.layoutSubviews()
                let frame = vc.view.frame
                if let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue, notification.name == UIResponder.keyboardWillShowNotification {
                    let rect = value.cgRectValue
                    vc.keyboardFrame = rect
                    let changeY = rect.height// - (vc.tfNumBookTarget.frame.origin.y + vc.tfNumBookTarget.frame.height)
                    vc.view.frame = .init(x: frame.origin.x, y: frame.origin.y - changeY, width: frame.width, height: frame.height)
                } else if notification.name == UIResponder.keyboardWillHideNotification {
                    vc.view.frame.origin.y = UIScreen.main.bounds.height - frame.height
                }
            })
            .disposed(by: self.disposeBag)
    }
    
//    @objc func keyboardWillShow(_ notification: Notification) {
//        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
//            let keyboardRectangle = keyboardFrame.cgRectValue
//            let keyboardHeight = keyboardRectangle.height
////            bottomBtnStartWhenActiveKeyBoard.constant = keyboardHeight + 10.0
//        }
//    }
    
    private func initView() {
        // Disable slide down to dismiss popup
        // to avoid conflict when slide slider
        //view.gestureRecognizers?.removeAll()
        
        // Show hide view slider by targetModeId
        // to avoid user can edit target number in case fixValue
//        switch targetModeId {
//        case TargetModeId.setByUser:
//            targetSlider.isHidden = true
//        default:
//            targetSlider.isHidden = true
//            // In case user cannot modify targetNumber
//            // then set targetNumber = maxSlider
//            targetNumber = maxSlider
//        }
        
        //lbSlogan.text = "READ_MORE_BOOK_SLOGAN".localized()
        btnStart.setTitle("BUTTON_START_CHALLENGE".localized(), for: .normal)
        
        // Init View for Slider
//        targetSlider.setup()
//
//        targetSlider.minimumValue = minSlider
//        targetSlider.maximumValue = maxSlider
//        targetSlider.value = targetNumber
//        targetSlider.isContinuous = false
        
        // Init Text
//        lbTarget.text = String(format: "FORMAT_SET_TARGET_OF_CHALLENGE".localized(),
//                               targetNumber, maxSlider, duration)
    }
    
    private func activeKeyBoard(){
        tfNumBookTarget.becomeFirstResponder()
        if self.targetNumber != 0 {
            tfNumBookTarget.text = String(Int(targetNumber))
        } else {
            tfNumBookTarget.text = "\(Int(maxSlider))"
        }
    }
    
    
    @IBAction func onJoinChallenge(_ sender: Any) {
        
        guard let numBookTargetString = tfNumBookTarget.text else {return}
        guard let numBookTarget = Int(numBookTargetString) else {return}
        if numBookTarget > 0 {
            // Send event back to screen Challenge detail
            SwiftEventBus.post(
                JoinChallengeEvent.EVENT_NAME,
                sender: JoinChallengeEvent(numBookTarget)
            )
            
            // Close popup Join Challenge
            dismiss(animated: true, completion: nil)
        } else {
            ToastView.makeToast("ALERT_SET_TARGET_JOIN_CHALLENGE".localized())
        }

        
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
