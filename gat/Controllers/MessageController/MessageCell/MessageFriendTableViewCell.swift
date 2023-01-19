//
//  MessageFriendTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 22/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxGesture

class MessageFriendTableViewCell: UITableViewCell {

    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    weak var controller: MessageViewController?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.friendImageView.circleCorner()
    }

    func setupUI(message: Message) {
        if message.user?.id == User.adminId {
            self.setupAdmin()
        } else {
            self.setupFriend(user: message.user!)
        }
        self.messageLabel.text = message.content
        self.messageLabel.sizeToFit()
        
        self.messageView.layer.borderColor = BORDER_MESSAGE_COLOR.cgColor
        self.messageView.layer.borderWidth = 0.5
        self.messageView.cornerRadius(radius: 15.0)
    }
    
    fileprivate func setupFriend(user: Profile) {
        self.friendImageView.isUserInteractionEnabled = true
        self.friendImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: user.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        self.friendImageView.circleCorner()
    }
    
    fileprivate func setupAdmin() {
        self.friendImageView.image = ADMIN_ICON
        self.friendImageView.circleCorner()
    }
    
//    fileprivate func event() {
//        self.friendImageView.rx.tapGesture().when(.recognized).bind { [weak self] (_) in
//            guard self?.user?.id != User.adminId else {
//                return
//            }
//            self?.controller?.performSegue(withIdentifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: self?.user)
//        }.addDisposableTo(self.disposeBag)
//    }

}
