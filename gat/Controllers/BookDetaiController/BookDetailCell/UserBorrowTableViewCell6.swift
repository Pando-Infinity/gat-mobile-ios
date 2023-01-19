//
//  UserBorrowTableViewCell6.swift
//  gat
//
//  Created by Vũ Kiên on 26/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class UserBorrowTableViewCell6: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var activeView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var limitBorrowButton: UIButton!
    
    weak var controller: ListBorrowViewController?
    fileprivate var userSharingBook: UserSharingBook?
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.statusLabel.text = Gat.Text.ListSharingBook.BOOKSTOP_MEMBER_ONLY_TITLE.localized()
        self.limitBorrowButton.setTitle(Gat.Text.ListSharingBook.LIMITED_BORROW_TITLE.localized(), for: .normal)
        self.limitBorrowButton.layer.borderColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1)
        self.limitBorrowButton.layer.borderWidth = 1.2
        self.limitBorrowButton.cornerRadius(radius: 5.0)
        self.event()
    }
    
    func setup(userSharingBook: UserSharingBook) {
        self.userSharingBook = userSharingBook
        self.setup(profile: userSharingBook.profile)
        self.setup(distance: userSharingBook.distance)
        self.setupActiveView(active: userSharingBook.activeFlag)
        self.label.text = Gat.Text.ListSharingBook.BEING_BORROWED_STATUS_TITLE.localized()
        self.label.isHidden = !userSharingBook.availableStatus
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
        self.userImageView.isUserInteractionEnabled = true
        self.userImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                guard let userSharingBook = self?.userSharingBook else {
                    return
                }
                let bookstop = Bookstop()
                bookstop.id = userSharingBook.profile.id
                bookstop.profile = userSharingBook.profile
                self?.controller?.performSegue(withIdentifier: "showBookstopOrganization", sender: bookstop)
            })
            .disposed(by: self.disposeBag)
    }

}
