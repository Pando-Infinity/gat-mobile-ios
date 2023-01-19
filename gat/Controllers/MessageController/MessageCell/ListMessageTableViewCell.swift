//
//  ListMessageTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 22/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxGesture
import RxSwift
import RealmSwift

class ListMessageTableViewCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    var index: Int!
    weak var viewcontroller: ListMessageViewController?
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(group: GroupMessage) {
        self.reset()
        guard let message = group.lastMessage else { return }
        if message.user?.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
            self.messageLabel.text = "\(Gat.Text.Message.YOURSELF.localized()): \(message.content)"
        } else if message.user?.id == User.adminId {
            self.messageLabel.text = "GaT: \(message.content)"
        } else {
            self.messageLabel.text = message.content
        }
        self.dateLabel.text = AppConfig.sharedConfig.calculatorDay(date: message.sendDate)
        if message.isRead || message.user?.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
            self.messageLabel.textColor = MESSAGE_UNREAD_COLOR
            self.messageLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.regular)
        } else {
            self.messageLabel.textColor = .black
            self.messageLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold)
        }
        self.setupUser(in: group)
        self.updateStatus(group: group)
    }
    
    fileprivate func reset() {
        self.layoutSubviews()
        self.layoutIfNeeded()
        self.tag = index
        self.messageLabel.text = ""
        self.nameLabel.text = ""
        self.userImageView.image = DEFAULT_USER_ICON
        self.userImageView.circleCorner()
        self.dateLabel.text = ""
        self.isUserInteractionEnabled = false
    }
    
    fileprivate func setupUser(in group: GroupMessage) {
        self.isUserInteractionEnabled = true
        guard let user = group.users.first(where: {$0.id != Repository<UserPrivate, UserPrivateObject>.shared.get()?.id}) else { return }
            self.nameLabel.text = user.name
            self.userImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: user.imageId)), placeholderImage: DEFAULT_USER_ICON)
    }
    
    fileprivate func updateStatus(group: GroupMessage) {
        if group.lastMessage?.user?.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id && group.lastMessage?.readTime.first(where: { $0.key != "\(Repository<UserPrivate, UserPrivateObject>.shared.get()!.id)" }) != nil {
            self.statusLabel.text = Gat.Text.Message.READ_STATUS.localized()
        } else {
            self.statusLabel.text = ""
        }
    }
}
