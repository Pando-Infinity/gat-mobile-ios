//
//  BookstopOrganizationDetailView.swift
//  gat
//
//  Created by Vũ Kiên on 12/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import ExpandableLabel

class BookstopOrganizationDetailView: UIView {

    @IBOutlet weak var bookstopImageView: UIImageView!
    @IBOutlet weak var nameBookstopLabel: UILabel!
    @IBOutlet weak var numberMembersLabel: UILabel!
    @IBOutlet weak var membersLabel: UILabel!
    @IBOutlet weak var numberBooksLabel: UILabel!
    @IBOutlet weak var booksLabel: UILabel!
    @IBOutlet weak var aboutLabel: ExpandableLabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    weak var controller: BookstopOriganizationViewController?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addressLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 16.0
        self.aboutLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 16.0
        self.membersLabel.text = Gat.Text.BookstopOrganization.MEMBERS_TITLE.localized()
        self.booksLabel.text = Gat.Text.BookstopOrganization.BOOKS_TITLE.localized()
        self.event()
        self.aboutLabel.numberOfLines = 3
        self.aboutLabel.delegate = self
    }
    
    func setupUI(user: Profile) {
        self.layoutIfNeeded()
        self.bookstopImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: user.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        self.bookstopImageView.layer.borderColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1)
        self.bookstopImageView.layer.borderWidth = 1.0
        self.bookstopImageView.circleCorner()
        self.nameBookstopLabel.text = user.name
        self.addressLabel.text = user.address
        self.setupAbout(user.about)
    }
    
    fileprivate func setupAbout(_ about: String) {
        guard !about.isEmpty else { return }
        self.aboutLabel.text = about
        self.aboutLabel.collapsed = true
        self.aboutLabel.shouldCollapse = true
        self.aboutLabel.collapsedAttributedLink = NSAttributedString(string: Gat.Text.BookDetail.MORE_TITLE.localized(), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
        self.aboutLabel.expandedAttributedLink = NSAttributedString.init(string: Gat.Text.LESS_TITLE.localized(), attributes:  [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
    }
    
    fileprivate func event() {
        self.showListBook()
        self.showMember()
    }
    
    fileprivate func showListBook() {
        self.numberBooksLabel
            .rx.tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.controller?.performSegue(withIdentifier: "showListBookInBookstop", sender: nil)
            }.disposed(by: self.disposeBag)
        self.booksLabel
            .rx.tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.controller?.performSegue(withIdentifier: "showListBookInBookstop", sender: nil)
            }.disposed(by: self.disposeBag)
    }
    
    fileprivate func showMember() {
        self.numberMembersLabel
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.controller?.performSegue(withIdentifier: "showMember", sender: nil)
            }
            .disposed(by: self.disposeBag)
        self.membersLabel
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.controller?.performSegue(withIdentifier: "showMember", sender: nil)
            }
            .disposed(by: self.disposeBag)
    }
}

extension BookstopOrganizationDetailView: ExpandableLabelDelegate {
    func willExpandLabel(_ label: ExpandableLabel) {
        self.controller?.view.layoutIfNeeded()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        self.controller?.view.layoutIfNeeded()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        self.controller?.view.layoutIfNeeded()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        self.controller?.view.layoutIfNeeded()
    }
}
