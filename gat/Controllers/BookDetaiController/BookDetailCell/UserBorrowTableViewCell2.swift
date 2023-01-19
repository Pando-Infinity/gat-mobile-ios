//
//  UserBorrow2TableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 19/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UserBorrowTableViewCell2: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var borrowButton: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var activeView: UIView!
    
    fileprivate let disposeBag = DisposeBag()
    weak var viewcontroller: ListBorrowViewController?
    fileprivate var userSharingBook: UserSharingBook!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.userImageView.isUserInteractionEnabled = true
       self.event()
    }
    
    // MARK: - UI
    func setup(userSharingBook: UserSharingBook) {
        self.userSharingBook = userSharingBook
        self.setup(profile: userSharingBook.profile)
        self.setup(distance: userSharingBook.distance)
        self.setupButton()
        self.setupActiveView(active: userSharingBook.activeFlag)
        self.setupHiddenButton(profile: userSharingBook.profile)
        self.statusLabel.text = Gat.Text.ListSharingBook.BEING_BORROWED_STATUS_TITLE.localized()
        self.statusLabel.isHidden = true
        self.setupHiddenStatusLabel(profile: userSharingBook.profile)
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
        if distance.isLessThanOrEqualTo(-1) || !distance.isLess(than: 20_000_000.0) {
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
    
    fileprivate func setupButton() {
        self.borrowButton.isHidden = false
        self.borrowButton.isUserInteractionEnabled = false
        self.borrowButton.setTitle(Gat.Text.ListSharingBook.ON_HOLD_TITLE.localized(), for: .normal)
        self.borrowButton.cornerRadius(radius: 6.0)
        self.borrowButton.layer.borderColor = #colorLiteral(red: 0.6250830889, green: 0.6250981092, blue: 0.6250900626, alpha: 1)
        self.borrowButton.layer.borderWidth = 2.0
    }
    
    fileprivate func setupHiddenButton(profile: Profile) {
        Observable<Bool>
            .combineLatest(
                Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                Observable<Profile>.just(profile),
                resultSelector: { $0.id == $1.id }
            )
            .subscribe(self.borrowButton.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupHiddenStatusLabel(profile: Profile) {
//        Observable<Bool>
//            .combineLatest(
//                Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
//                Observable<Profile>.just(profile),
//                resultSelector: { $0.id == $1.id }
//            )
//            .subscribe(self.statusLabel.rx.isHidden)
//            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event    
    fileprivate func event() {
        self.showVistorUser()
        self.showRequest()
    }
    
    fileprivate func showVistorUser() {
        self.userImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .withLatestFrom(Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first })
            .subscribe(onNext: { [weak self] (userPrivate) in
                if let userId = userPrivate?.profile?.id, userId == self?.userSharingBook.profile.id {
                    let storyBoard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                    let vc = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                    vc.isShowButton.onNext(true)
                    self?.viewcontroller?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    if self?.userSharingBook.profile.userTypeFlag == .normal {
                        let userPublic = UserPublic()
                        userPublic.profile = self?.userSharingBook.profile ?? Profile()
                        self?.viewcontroller?.performSegue(withIdentifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: userPublic)
                    } else {
                        
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showRequest() {
        self.borrowButton
            .rx
            .controlEvent(.touchUpInside)
            .withLatestFrom(Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first })
            .do(onNext: { (userPrivate) in
                if userPrivate == nil {
                    HandleError.default.loginAlert()
                }
            })
            .filter { (userPrivate) in userPrivate != nil }
            .subscribe(onNext: { [weak self] (userPrivate) in
                self?.viewcontroller?.performSegue(withIdentifier: Gat.Segue.SHOW_REQUEST_DETAIL_BORROWER_INDETIFIER, sender: self?.userSharingBook)
            })
            .disposed(by: self.disposeBag)
    }

}
