//
//  CheckboxCollectionViewCell.swift
//  gat
//
//  Created by jujien on 05/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import BEMCheckBox

class CheckboxCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "checkBoxCell" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkBoxContainerView: UIView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupCheckBox(on: Bool) {
        self.checkBoxContainerView.subviews.forEach { $0.removeFromSuperview() }
        let checkBox = BEMCheckBox(frame: self.checkBoxContainerView.bounds)
        checkBox.boxType = .square
        checkBox.onFillColor = #colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1)
        checkBox.onCheckColor = .white
        checkBox.onTintColor = #colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1)
        checkBox.offFillColor = .clear
        checkBox.tintColor = #colorLiteral(red: 0.7019607843, green: 0.7294117647, blue: 0.768627451, alpha: 1)
        self.checkBoxContainerView.addSubview(checkBox)
        checkBox.isEnabled = false
        checkBox.on = on
    }
    
    func setupRadio(on: Bool) {
        self.layoutIfNeeded()
        self.checkBoxContainerView.subviews.forEach { $0.removeFromSuperview() }
        let radioView = UIView(frame: self.checkBoxContainerView.bounds)
        radioView.backgroundColor = .white
        radioView.cornerRadius = radioView.frame.width / 2.0
        radioView.borderColor = !on ? #colorLiteral(red: 0.7019607843, green: 0.7294117647, blue: 0.768627451, alpha: 1) : #colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1)
        radioView.borderWidth = 1.5
        self.checkBoxContainerView.addSubview(radioView)
        let selectedView = UIView(frame: .init(x: 4.0, y: 4.0, width: radioView.bounds.width - 8.0, height: radioView.bounds.height - 8.0))
        selectedView.cornerRadius = selectedView.bounds.width / 2.0
        selectedView.backgroundColor = !on ? .white : #colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1)
        radioView.addSubview(selectedView)
    }

}
