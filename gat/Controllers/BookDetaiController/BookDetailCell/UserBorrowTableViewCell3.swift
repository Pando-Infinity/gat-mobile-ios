//
//  UserBorrowTableViewCell3.swift
//  
//
//  Created by Vũ Kiên on 19/04/2017.
//
//

import UIKit
import RxCocoa
import RxSwift
import RxGesture

class UserBorrowTableViewCell3: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var forwardImageView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var activeView: UIView!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var userSharingBook: UserSharingBook!
    
    weak var viewcontroller: ListBorrowViewController?
    
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
        self.setupActiveView(active: userSharingBook.activeFlag)
        self.setupHidden(profile: userSharingBook.profile)
        self.setupStatus(recordStatus: userSharingBook.request!.recordStatus!)
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
    
    fileprivate func setupHidden(profile: Profile) {
        self.statusLabel.isHidden = true
        self.forwardImageView.isHidden = true
        Observable<Bool>
            .combineLatest(
                Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                Observable<Profile>.just(profile),
                resultSelector: { $0.id == $1.id }
            )
            .subscribe(onNext: { [weak self] (isHidden) in
                self?.statusLabel.isHidden = isHidden
                self?.forwardImageView.isHidden = isHidden
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupStatus(recordStatus: RecordStatus) {
        switch recordStatus {
        case .waitConfirm:
            self.statusLabel.text = Gat.Text.ListSharingBook.ON_HOLD_AGREE_STATUS_TITLE.localized()
            break
        /*case .onHold:
            self.statusLabel.text = Gat.Text.ListSharingBook.ON_HOLD_RETURN_STATUS_TITLE
            break*/
        case .contacting:
            self.statusLabel.text = Gat.Text.ListSharingBook.DOING_CONTACT_STATUS_TITLE.localized()
            break
        case .borrowing:
            self.statusLabel.text = Gat.Text.ListSharingBook.BORROWING_STATUS_TITLE.localized()
            break
        default:
            self.statusLabel.text = ""
            break
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

}
