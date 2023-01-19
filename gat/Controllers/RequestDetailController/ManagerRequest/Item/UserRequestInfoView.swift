//
//  InfoUserView.swift
//  gat
//
//  Created by Vũ Kiên on 04/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol UserRequestInfoDelegate: class {
    func showVistorUser(identifier: String, sender: Any?)
    
    func showMessage(groupId: String)
}

class UserRequestInfoView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var numberSharingBookLabel: UILabel!
    @IBOutlet weak var numberReviewBookLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    
    weak var delegate: UserRequestInfoDelegate?
    fileprivate var profile: Profile?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.event()
    }
    
    fileprivate func saveUser() {
        Repository<Profile, ProfileObject>.shared.save(object: self.profile!).subscribe().disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    func setup(profile: Profile) {
        self.profile = profile
        self.layoutIfNeeded()
        self.imageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.imageView.circleCorner()
        self.nameLabel.text = profile.name
        self.addressLabel.text = profile.address
        self.messageButton.setTitle(String(format: Gat.Text.BorrowerRequestDetail.SEND_MESSAGE_TO_TITLE.localized(), profile.name), for: .normal)
    }
    
    func setup(numberBook: Int, numberReview: Int) {
        self.numberSharingBookLabel.text = "\(numberBook)"
        self.numberReviewBookLabel.text = "\(numberReview)"
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.imageEvent()
        self.messageButtonEvent()
    }
    
    fileprivate func imageEvent() {
        self.imageView
            .rx
            .tapGesture()
            .when(.recognized)
            .flatMap({ [weak self] (_) -> Observable<Profile> in
                return Observable<Profile>.from(optional: self?.profile)
            })
            .subscribe(onNext: { [weak self] (profile) in
                if profile.userTypeFlag == .normal {
                    self?.delegate?.showVistorUser(identifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: profile)
                } else {
                    let bookstop = Bookstop()
                    bookstop.id = profile.id
                    bookstop.profile = profile
                    self?.delegate?.showVistorUser(identifier: "showBookstopOrganization", sender: bookstop)
                }
                
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func messageButtonEvent() {
        self.messageButton
            .rx
            .tap
            .asObservable()
            .flatMap { [weak self] (_) -> Observable<String> in
                guard let profile = self?.profile else {
                    return Observable.empty()
                }
                return Observable<String>
                    .combineLatest(Repository<UserPrivate, UserPrivateObject>.shared.getFirst(), Observable<Profile>.just(profile), resultSelector: { (userPrivate, profile) -> String in
                        return userPrivate.id > profile.id ? "\(profile.id):\(userPrivate.id)" : "\(userPrivate.id):\(profile.id)"
                    })
            }
            .subscribe(onNext: { [weak self] (groupId) in
                self?.saveUser()
                self?.delegate?.showMessage(groupId: groupId)
            })
            .disposed(by: self.disposeBag)
    }

}
