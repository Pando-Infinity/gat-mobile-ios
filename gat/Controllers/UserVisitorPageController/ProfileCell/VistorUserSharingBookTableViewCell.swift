//
//  VistorUserSharingBookTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 02/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift

class VistorUserSharingBookTableViewCell: UITableViewCell {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var statusMessageLabel: UILabel!
    @IBOutlet weak var borrowButton: UIButton!
    @IBOutlet weak var statusView: UIStackView!
    @IBOutlet weak var statusLabel: UILabel!
    
    weak var controller: SharingBookContainerController?
    fileprivate var userSharingBook: UserSharingBook!
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
    }
    

    //MARK: - UI
    func setup(userSharingBook: UserSharingBook) {
        self.layoutIfNeeded()
        self.userSharingBook = userSharingBook
        self.setup(bookInfo: userSharingBook.bookInfo)
        self.borrowButton.cornerRadius(radius: self.borrowButton.frame.height / 2.0)
        self.statusMessageLabel.text = !userSharingBook.availableStatus ? Gat.Text.VistorUserProfile.BookSharing.DOING_BORROWED_STATUS.localized() : ""//Gat.Text.borrowing_request_status_did_borrowed : ""
        self.configure(userSharingBook: userSharingBook)
        if let recordStatus = userSharingBook.request?.recordStatus {
            self.setupStatus(recordStatus)
        } else {
            self.statusLabel.text = ""
        }
    }
    
    fileprivate func setup(bookInfo: BookInfo) {
        self.nameLabel.text = bookInfo.title
        self.authorLabel.text = bookInfo.author
        self.setupRating(bookInfo.rateAvg)
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookInfo.imageId)), placeholderImage: DEFAULT_BOOK_ICON)
    }
    
    fileprivate func setupRating(_ rating: Double) {
        self.layoutIfNeeded()
        self.ratingView.rating = rating
        self.ratingView.text = String(format: "%.2f", rating)
        self.ratingView.settings.starSize = Double(self.ratingView.frame.height)
        self.ratingView.isUserInteractionEnabled = false
    }
    
    fileprivate func setupStatus(_ recordStatus: RecordStatus) {
        switch recordStatus {
        case .waitConfirm:
            self.statusLabel.text = Gat.Text.VistorUserProfile.BookSharing.WATING_CONFIRM_STATUS.localized()
            break
//        case .onHold:
//            self.statusLabel.text = Gat.Text.VistorUserProfile.BookSharing.ON_HOLD_STATUS
//            break
        case .contacting:
            self.statusLabel.text = Gat.Text.VistorUserProfile.BookSharing.CONTACTING_STATUS.localized()
            break
        case .borrowing:
            self.statusLabel.text = Gat.Text.VistorUserProfile.BookSharing.BORROWING_STATUS.localized()
            break
        default:
            self.statusLabel.text = ""
            break
        }
    }
    
    fileprivate func configure(userSharingBook: UserSharingBook) {
        if userSharingBook.availableStatus {
            if userSharingBook.request == nil {
                self.borrowButton.isHidden = false
                self.borrowButton.isUserInteractionEnabled = true 
                self.borrowButton.setTitle(Gat.Text.VistorUserProfile.BookSharing.BORROW_BOOK_TITLE.localized(), for: .normal)
                self.borrowButton.backgroundColor = Gat.Color.visitorBorrowingBook
                self.borrowButton.setTitleColor(.white, for: .normal)
                self.borrowButton.cornerRadius(radius: self.borrowButton.frame.height / 2.0)
                self.borrowButton.layer.borderWidth = 0.0
                self.borrowButton.layer.borderColor = UIColor.clear.cgColor
                self.statusView.isHidden = true
                self.statusMessageLabel.isHidden = true
            } else {
                self.statusView.isHidden = false
                self.borrowButton.isHidden = true
                self.statusMessageLabel.isHidden = true
            }
        } else {
            if userSharingBook.request == nil {
                self.borrowButton.isHidden = false
                self.borrowButton.isUserInteractionEnabled = false
                self.borrowButton.setTitle(Gat.Text.VistorUserProfile.BookSharing.WAITING_BORROW_BOOK_TITLE.localized(), for: .normal)
                self.borrowButton.backgroundColor = .white//Gat.Color.visitorWaitBorrowing
                self.borrowButton.setTitleColor(#colorLiteral(red: 0.6250830889, green: 0.6250981092, blue: 0.6250900626, alpha: 1), for: .normal)
                self.borrowButton.cornerRadius(radius: 4.0)
                self.borrowButton.layer.borderWidth = 2.0
                self.borrowButton.layer.borderColor = #colorLiteral(red: 0.6250830889, green: 0.6250981092, blue: 0.6250900626, alpha: 1)
                self.statusMessageLabel.isHidden = true
                self.statusView.isHidden = true
            } else {
                self.statusView.isHidden = false
                self.statusMessageLabel.isHidden = false
                self.borrowButton.isHidden = true
            }
        }
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.showBookDetail()
        self.borrowBookEvent()
    }
    
    fileprivate func showBookDetail() {
        self.bookImageView
            .rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.controller?.userVistorController?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.userSharingBook.bookInfo)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func borrowBookEvent() {
        self.borrowButton.rx.tap
            .do(onNext: { (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { Session.shared.isAuthenticated }
            .subscribe(onNext: { [weak self] (_) in
                self?.controller?.userVistorController?.performSegue(withIdentifier: Gat.Segue.SHOW_REQUEST_DETAIL_BORROWER_INDETIFIER, sender: self?.userSharingBook)
            })
            .disposed(by: self.disposeBag)
    }

}
