//
//  BookstopDetailView.swift
//  gat
//
//  Created by Vũ Kiên on 28/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit

class BookstopDetailView: UIView {

    @IBOutlet weak var bookstopImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var bookstopImageCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookstopImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookstopImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabelCenterYConstraint: NSLayoutConstraint!
    
    fileprivate var CONSTANT_LEADING_IMAGE: CGFloat = 0.0
    weak var controller: BookStopViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.CONSTANT_LEADING_IMAGE = self.bookstopImageLeadingConstraint.constant
    }
    
    func setupUI(bookstop: Bookstop) {
        self.nameLabel.text = bookstop.profile?.name
        self.addressLabel.text = bookstop.profile?.address
        self.addressLabel.sizeToFit()
        self.bookstopImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookstop.profile!.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        self.setupImage()
    }
    
    fileprivate func setupImage() {
        self.layoutIfNeeded()
        self.bookstopImageView.circleCorner()
        self.bookstopImageView.layer.borderColor = #colorLiteral(red: 0.8117647059, green: 0.9333333333, blue: 1, alpha: 1)
        self.bookstopImageView.layer.borderWidth = 1.5
    }
    
    func changeFrame(progress: CGFloat) {
        self.layoutIfNeeded()
        self.bookstopImageLeadingConstraint.constant = self.CONSTANT_LEADING_IMAGE * (1.0 - progress) + (self.controller!.backButton.frame.origin.y + self.controller!.backButton.frame.width) * progress
        self.bookstopImageWidthConstraint.constant = -progress * (self.bookstopImageWidthConstraint.multiplier - self.controller!.headerHeightConstraint.multiplier) * self.frame.width
        self.bookstopImageCenterYConstraint.constant = progress * UIApplication.shared.statusBarFrame.height / 2.0
        self.nameLabelCenterYConstraint.constant = progress * UIApplication.shared.statusBarFrame.height / 2.0
        self.nameLabelCenterYConstraint.constant = progress * (0.5 - self.nameLabelCenterYConstraint.multiplier / 2.0) * self.frame.height
        self.addressLabel.alpha = progress == 0.0 ? 1.0 : 0.0
        self.setupImage()
    }
}
