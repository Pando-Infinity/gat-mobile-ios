//
//  AlertView.swift
//  gat
//
//  Created by Vũ Kiên on 13/05/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AlertView: UIView {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.messageLabel.text = Gat.Text.CommonError.ERROR_CONNECT_INTERNET_MESSAGE.localized()
    }
    
    
    static func showAlert(frame: CGRect, in view: UIView) {
        let alert = Bundle.main.loadNibNamed(Gat.View.ALERT, owner: self, options: nil)?.first as! AlertView
        alert.frame = frame
        alert.frame.origin.y = -frame.height
        view.addSubview(alert)
        UIView.animate(withDuration: 0.5, animations: {
            alert.frame.origin.y = 0
        }) { (completed) in
            UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
                alert.frame.origin.y = -frame.height
            }, completion: { (completed) in
                alert.removeFromSuperview()
            })
        }
    }
    
}
