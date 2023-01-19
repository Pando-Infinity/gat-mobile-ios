//
//  MemberActivityTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 16/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol MemberActivityCellDelegate: class {
    func showView(identifier: String, sender: Any?)
    
    func showViewController(_ vc: UIViewController)
}

class MemberActivityTableViewCell: UITableViewCell {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userActivityLabel: UILabel!
    @IBOutlet weak var bookImageView: UIImageView!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var memberActivity: MemberActivity?
    
    weak var delegate: MemberActivityCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
        
    }
    
    func setup(memberActivity: MemberActivity) {
        self.memberActivity = memberActivity
        self.userImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: memberActivity.user.imageId)), placeholderImage: DEFAULT_USER_ICON)
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: memberActivity.book.imageId)), placeholderImage: DEFAULT_BOOK_ICON)
        self.layoutIfNeeded()
        self.userImageView.circleCorner()
        var text: String = ""//"\(memberActivity.user.name) bắt đầu mượn \"\(memberActivity.book.title)\"."
        if memberActivity.status == .borrow {
            text = String(format: Gat.Text.BookstopOrganization.MEMBER_BORROW_ACTIVITY.localized(), memberActivity.user.name, memberActivity.book.title, memberActivity.book.author)
        } else if memberActivity.status == .return {
            text = String(format: Gat.Text.BookstopOrganization.MEMBER_RETURN_ACTIVITY.localized(), memberActivity.user.name, memberActivity.book.title, memberActivity.book.author)
        }
        let attributes = NSMutableAttributedString(string: text + " \(self.time(date: memberActivity.activityTime))", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.1254901961, alpha: 1)])
        attributes.addAttributes([NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.568627451, green: 0.568627451, blue: 0.568627451, alpha: 1)], range: NSRange(location: text.count + 1, length: self.time(date: memberActivity.activityTime).count))
        self.userActivityLabel.attributedText = attributes
    }
    
    fileprivate func time(date: Date) -> String {
        return AppConfig.sharedConfig.calculatorDay(date: date)
    }


    fileprivate func event() {
        self.bookImageView.rx.tapGesture().when(.recognized).subscribe(onNext: {  [weak self] (_) in
            print("TAPPED BOOK IMAGE")
            self?.delegate?.showView(identifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.memberActivity?.book)
        }).disposed(by: self.disposeBag)
        
        self.userImageView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            print("TAPPED USER IMAGE")
            if self?.memberActivity?.user.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                vc.isShowButton.onNext(true)
                self?.delegate?.showViewController(vc)
            } else {
                self?.delegate?.showView(identifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER , sender: self?.memberActivity?.user)
            }
            
        }).disposed(by: self.disposeBag)
    }

}
