//
//  UserBorrowTableViewCell5.swift
//  gat
//
//  Created by Vũ Kiên on 16/08/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UserBorrowTableViewCell5: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var activeView: UIView!
    
    weak var viewcontroller: ListBorrowViewController?
    fileprivate let disposeBag = DisposeBag()
    fileprivate var userSharingBook: UserSharingBook!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.userImageView.isUserInteractionEnabled = true
        self.event()
    }

    func setup(userSharingBook: UserSharingBook) {
        self.userSharingBook = userSharingBook
        self.setup(profile: userSharingBook.profile)
        self.setup(distance: userSharingBook.distance)
        self.setupActiveView(active: userSharingBook.activeFlag)
        self.statusLabel.text = Gat.Text.ListSharingBook.READ_IN_PLACE_STATUS_TITLE.localized()
    }

    fileprivate func setup(profile: Profile) {
        self.layoutIfNeeded()
        self.userImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        self.userImageView.circleCorner()
        self.nameLabel.text = profile.name
        self.addressLabel.text = profile.address
    }
    
    fileprivate func setup(distance: Double) {
        self.distanceLabel.text = AppConfig.sharedConfig.stringDistance(distance)
        self.distanceLabel.isHidden = true
        if distance <= -1.0 || distance >= 20_000_000.0 {
            self.distanceLabel.isHidden = true
        } else {
            self.distanceLabel.isHidden = false
        }
    }
    
    fileprivate func setupActiveView(active: Bool) {
        self.layoutIfNeeded()
        self.activeView.layer.borderColor = active ? #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1) : #colorLiteral(red: 0.7607843137, green: 0.7607843137, blue: 0.7607843137, alpha: 1)
        self.activeView.layer.borderWidth = 1.5
        self.activeView.circleCorner()
    }
    
    fileprivate func event() {
        self.userImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                let bookstop = Bookstop()
                bookstop.profile = self?.userSharingBook.profile
                bookstop.id = self?.userSharingBook.profile.id ?? 0
                self?.viewcontroller?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER, sender: bookstop)
            })
            .disposed(by: self.disposeBag)
    }

}
