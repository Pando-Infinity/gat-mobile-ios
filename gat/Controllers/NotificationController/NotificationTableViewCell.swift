//
//  NotificationTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 25/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {

    @IBOutlet weak var notificationImageView: UIImageView!
    @IBOutlet weak var titleNotificationLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.notificationImageView.circleCorner()
    }

    func setup(notification: UserNotification) {
        if #available(iOS 9, *) {
            self.layoutIfNeeded()
            self.notificationImageView.circleCorner()
        }
        guard let user = notification.user else {
            return
        }
        if user.id == 0 {
            self.setupAdmin()
        } else if notification.notificationType == 0 {
            self.setupUnreadMessageIcon(user)
        } else if notification.notificationType == -1 {
            self.titleNotificationLabel.text = "Nguyen Quoc Anh"
            self.notificationImageView.image = #imageLiteral(resourceName: "nft_4")
        } else {
            self.setupUser(user)
        }
        self.setMessages(notification: notification)
        self.messageLabel.sizeToFit()
        self.dateLabel.text = AppConfig.sharedConfig.calculatorDay(date: notification.beginTime)
    }
    
    fileprivate func setupAdmin() {
        self.notificationImageView.image = ADMIN_ICON
        self.titleNotificationLabel.text = Gat.Text.ADMIN_NAME
    }

    fileprivate func setupUnreadMessageIcon(_ user: Profile) {
        self.notificationImageView.image = ADMIN_ICON
        self.titleNotificationLabel.text = user.name
    }

    fileprivate func setupUser( _ user: Profile) {
        self.notificationImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: user.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.titleNotificationLabel.text = user.name
    }

    fileprivate func setMessages(notification: UserNotification) {
        switch notification.notificationType {
        case -1:
            self.messageLabel.text = "Give 20 GAT to your review on the design of everyday things"
            break
        case 0:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_0_TITLE.localized(), notification.referId)
            break
        case 1:
            self.messageLabel.text = Gat.Text.Notification.Code.NOTIFICATION_TYPE_1_TITLE.localized()
            break
        case 10:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_10_TITLE.localized(), notification.targetName)
            break
        case 11:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_11_TITLE.localized(), notification.targetName)
            break
        case 12:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_12_TITLE.localized(), notification.targetName)
            break
        case 13:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_13_TITLE.localized(), notification.targetName)
            break
        case 14:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_14_TITLE.localized(), notification.targetName)
            break
        case 15:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_15_TITLE.localized(), notification.targetName)
            break
        case 16:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_16_TITLE.localized(), notification.targetName)
            break
        case 17:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_17_TITLE.localized(), notification.targetName)
            break
        case 18:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_18_TITLE.localized(), notification.referId, notification.targetName)
            break
        case 19:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_19_TITLE.localized(), notification.targetName)
            break
        case 20:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_20_TITLE.localized(), notification.targetName, notification.referName)
            break
        case 21:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_21_TITLE.localized(), notification.targetName, notification.referName)
            break
        case 120:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_120_TITLE.localized(), notification.referId)
            break
        case 121:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_121_TITLE.localized(), notification.targetName, notification.referName)
            break
        case 122:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_122_TITLE.localized(), notification.targetName)
            break
        case 123:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_123_TITLE.localized(), notification.targetName)
            break
        case 200:
            self.messageLabel.text = Gat.Text.Notification.Code.NOTIFICATION_TYPE_200_TITLE.localized()
            break
        case 201:
            self.messageLabel.text = Gat.Text.Notification.Code.NOTIFICATION_TYPE_201_TITLE.localized()
            break
        case 202:
            self.messageLabel.text = Gat.Text.Notification.Code.NOTIFICATION_TYPE_202_TITLE.localized()
            break
        case 203:
            self.messageLabel.text = Gat.Text.Notification.Code.NOTIFICATION_TYPE_203_TITLE.localized()
            break
        case 301:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_301_TITLE.localized(), notification.referId)
            break
        case 500:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_500_TITLE.localized(), notification.targetName)
        case 502:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_502_TITLE.localized(), notification.referId)
        case 600:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_600_TITLE.localized(), notification.referName)
        case 800:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_800_TITLE.localized(), notification.referName)
        case 801:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_801_TITLE.localized(), notification.referName)
        case 802:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_802_TITLE.localized(), "")
        case 803:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_803_TITLE.localized(), notification.referName)
        case 900:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_900_TITLE.localized(), notification.referName)
        case 901:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_901_TITLE.localized(), notification.referName, notification.relationCount)
        case 902:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_902_TITLE.localized(), notification.referName)
        case 903:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_903_TITLE.localized(), notification.referName, notification.relationCount)
        case 904:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_904_TITLE.localized(), notification.referName)
        case 905:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_905_TITLE.localized(), notification.referName, notification.relationCount)
        case 906:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_906_TITLE.localized(), notification.referName)
        case 907:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_907_TITLE.localized(), notification.referName,notification.relationCount)
        case 908:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_908_TITLE.localized(), notification.referName)
        case 909:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_909_TITLE.localized(), notification.referName)
        case 910:
            self.messageLabel.text = String(format: Gat.Text.Notification.Code.NOTIFICATION_TYPE_910_TITLE.localized(), notification.referName)
            break
        default:
            break
        }
    }
}
