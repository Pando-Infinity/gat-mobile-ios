//
//  ToastView.swift
//  QuocNV
//

import UIKit

class ToastView : NSObject {
    var toastView: UIView!
    static var shared = ToastView()
    private var lbContent: UILabel!
    private var dismissTime: Double = 0
    private var textContent = ""
    private var isShowToast = false
    private var duration = 2.0
    
    static func makeToast(_ content: String , duration: Double = 2.0) {
        shared.showToast(content, duration: duration)
    }
    
    private func showToast(_ content: String, duration: Double) {
        initToastInstance()
        self.textContent = content
        self.duration = duration
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layoutToastViewFrame()
        animateShowToast(duration: self.duration)
    }
    
    private func initToastInstance() {
        if toastView != nil {
            toastView.removeFromSuperview()
            return
        }
        toastView = UIView()
        toastView.isUserInteractionEnabled = false
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        toastView.layer.cornerRadius = 4
        toastView.clipsToBounds = true
        lbContent = UILabel()
        lbContent.textAlignment = .center
        lbContent.textColor = UIColor.white
        lbContent.font = UIFont.systemFont(ofSize: 15)
        lbContent.numberOfLines = 0
        toastView.addSubview(lbContent)
    }
    
    private func layoutToastViewFrame() {
        let windowSize = UIScreen.main.bounds
        let toastWidth = min(windowSize.width, windowSize.height) * 0.9
        let toastOriginX = toastWidth / 18.0
        lbContent.text = textContent
        let textWidth = toastWidth - 24
        let baseRect = CGRect(origin: .zero, size: CGSize.init(width: textWidth, height: 1000))
        var textRect = lbContent.textRect(forBounds: baseRect, limitedToNumberOfLines: 3)
        if textRect.size.height < 24 {
            textRect.size.height = 24
        }
        toastView.frame = CGRect(x: toastOriginX, y: windowSize.height, width: toastWidth, height: textRect.height + 16)
        lbContent.frame = CGRect(x: 8, y: 8, width: textWidth, height: textRect.height)
    }
    
    private func animateShowToast(duration: Double) {
        var toastFrame = toastView.frame
        let windowSize = UIScreen.main.bounds
        toastFrame.origin.y = windowSize.height - toastFrame.height - 120
        let activeWindow = (UIApplication.shared.delegate as! AppDelegate).window
        activeWindow?.addSubview(toastView)
        UIView.animate(withDuration: 0.2, animations: {
            self.toastView.frame = toastFrame
        }) { (animated) in
            if animated {
                self.isShowToast = true
                self.scheduleDismissToast(duration: duration)
            }
        }
    }
    
    func scheduleDismissToast(duration: Double) {
        let newDismisTime = round(Date().timeIntervalSince1970 + duration)
        self.dismissTime = newDismisTime
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if self.dismissTime == newDismisTime && self.isShowToast {
                self.pressedDismiss()
            }
        }
    }
    
    @objc fileprivate func pressedDismiss() {
        toastView.removeFromSuperview()
        isShowToast = false
    }
}
