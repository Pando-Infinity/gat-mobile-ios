//
//  BorrowingRequestTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 14/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BorrowingRequestTableViewCell: UITableViewCell {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var requestTitleLabel: UILabel!
    @IBOutlet weak var statusRequestLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var requestAlertView: UIView!
    @IBOutlet weak var requestDetailHeightConstraint: NSLayoutConstraint!
    
    weak var controller: BorrowingRequestContainer?
    fileprivate var bookRequest: BookRequest!
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.rejectButton.setTitle(Gat.Text.UserProfile.Request.REJECT_TITLE.localized(), for: .normal)
        self.acceptButton.setTitle(Gat.Text.UserProfile.Request.ACCEPT_TITLE.localized(), for: .normal)
        self.data()
        self.event()
    }
    
    fileprivate func data() {
        Observable
            .of(self.acceptEvent(), self.rejectEvent())
            .merge()
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.controller?.view.isUserInteractionEnabled = false
            })
            .flatMapLatest { [weak self] (bookRequest, newStatus) in
                Observable<((), RecordStatus)>
                    .combineLatest(
                        RequestNetworkService
                            .shared
                            .update(owner: bookRequest, newStatus: newStatus)
                            .catchError({ [weak self] (error) -> Observable<()> in
                                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                                HandleError.default.showAlert(with: error, action: { [weak self] in
                                    self?.controller?.showStatus = .new
                                    self?.controller?.page.onNext(1)
                                    self?.controller?.view.isUserInteractionEnabled = true
                                })
                                return Observable.empty()
                            }),
                        Observable<RecordStatus>.just(newStatus),
                        resultSelector: { ($0, $1) }
                )
            }
            .map { (_, newStatus) in newStatus }
            .flatMapLatest { [weak self] (recordStatus) -> Observable<BookRequest> in
                self?.bookRequest.recordStatus = recordStatus
                return Observable<BookRequest>.from(optional: self?.bookRequest)
            }
            .do(onNext: { [weak self] (bookRequest) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.controller?.view.isUserInteractionEnabled = true
                guard let value = try? self?.controller?.items.value(), var items = value else {
                    return
                }
                items[0].items.filter { $0.recordId == bookRequest.recordId }.first?.recordStatus = bookRequest.recordStatus
                self?.controller?.items.onNext(items)
            })
            .flatMapLatest { Repository<BookRequest, BookRequestObject>.shared.save(object: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }

    //MARK: - UI
    func setup(bookRequest: BookRequest) {
        self.bookRequest = bookRequest
        switch bookRequest.recordType! {
        case .sharing:
            self.setup(profile: bookRequest.borrower!)
            self.setupRequestTitleLabel(title: Gat.Text.UserProfile.Request.BORROWER_REQUEST_TITLE.localized(), bookName: bookRequest.book!.title)
            if bookRequest.recordStatus == .waitConfirm {
                self.requestAlertView.isHidden = false
                self.requestDetailHeightConstraint.constant = 0.0
            } else {
                self.requestAlertView.isHidden = true
                self.requestDetailHeightConstraint.constant = (1.0 - self.requestDetailHeightConstraint.multiplier) * self.frame.height
            }
            break
        case .borrowing:
            self.setup(profile: bookRequest.owner!)
            self.setupRequestTitleLabel(title: Gat.Text.UserProfile.Request.OWNER_REQUEST_TITLE.localized(), bookName: bookRequest.book!.title)
            self.requestAlertView.isHidden = true
            self.requestDetailHeightConstraint.constant = (1.0 - self.requestDetailHeightConstraint.multiplier) * self.frame.height
            break
        }
        self.setupStatus(bookRequest.recordStatus!)
    }
    
    fileprivate func setup(profile: Profile) {
        self.layoutIfNeeded()
        self.userImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId))!, placeholderImage: DEFAULT_USER_ICON)
        self.nameLabel.text = profile.name
        self.userImageView.circleCorner()
    }
    
    fileprivate func setupRequestTitleLabel(title: String, bookName: String) {
        let text = String(format: title, bookName)
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)], range: (text as NSString).range(of: bookName))
        self.requestTitleLabel.attributedText = attributedText
        self.requestTitleLabel.sizeToFit()
    }
    
    fileprivate func setupStatus(_ status: RecordStatus) {
        switch status {
        case .waitConfirm:
            self.statusRequestLabel.text = Gat.Text.UserProfile.Request.WAITING_CONFIRM_STATUS.localized()//Gat.Text.borrowing_request_status_wait_confirm
            break
        case .onHold:
            self.statusRequestLabel.text = Gat.Text.UserProfile.Request.ON_HOLD_STATUS.localized()//Gat.Text.borrowing_request_status_onhold
            break
        case .contacting:
            self.statusRequestLabel.text = Gat.Text.UserProfile.Request.CONTACTING_STATUS.localized()//Gat.Text.borrowing_request_status_contacting
            break
        case .borrowing:
            self.statusRequestLabel.text = Gat.Text.UserProfile.Request.BORROWING_STATUS.localized()//Gat.Text.borrowing_request_status_borrowing
            break
        case .completed:
            self.statusRequestLabel.text = Gat.Text.UserProfile.Request.RETURNED_STATUS.localized()//Gat.Text.borrowing_request_status_returned
            break
        case .rejected:
            self.statusRequestLabel.text = Gat.Text.UserProfile.Request.REJECTED_STATUS.localized()//Gat.Text.borrowing_request_status_rejected
            break
        case .cancelled:
            self.statusRequestLabel.text = Gat.Text.UserProfile.Request.CANCELLED_STATUS.localized()//Gat.Text.borrowing_request_status_canceled
            break
        case .unreturned:
            self.statusRequestLabel.text = Gat.Text.UserProfile.Request.UNRETURNED_STATUS.localized()//Gat.Text.borrowing_request_status_unreturned
            break
        default: break 
        }
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.userImageEvent()
        self.requestTitleLabelEvent()
    }
    
    fileprivate func userImageEvent() {
        self.userImageView.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                guard let bookRequest = self?.bookRequest else { return }
                if bookRequest.recordType == .sharing || (bookRequest.recordType == .borrowing && bookRequest.owner!.userTypeFlag == .normal) {
                    let userPublic = UserPublic()
                    if bookRequest.recordType == .sharing {
                        userPublic.profile = bookRequest.borrower!
                    } else if bookRequest.recordType == .borrowing {
                        userPublic.profile = bookRequest.owner!
                    }
                    self?.controller?.profileViewController?.performSegue(withIdentifier: Gat.Segue.openVisitorPage, sender: userPublic)
                } else if bookRequest.recordType == .borrowing && bookRequest.owner!.userTypeFlag == .organization {
                    let bookstop = Bookstop()
                    bookstop.id = bookRequest.owner!.id
                    bookstop.profile = bookRequest.owner!
                    self?.controller?.profileViewController?.performSegue(withIdentifier: BookstopOriganizationViewController.segueIdentifier, sender: bookstop)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func requestTitleLabelEvent() {
        self.requestTitleLabel
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (gesture) in
                guard let bookName = self?.bookRequest.book?.title, let text = self?.requestTitleLabel.text, let sizeBookName = self?.requestTitleLabel.text?.stringSize(text: bookName, with: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)]), let sizeText = self?.requestTitleLabel.text?.stringSize(text: text, with: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)]) else {
                    return
                }
                guard let index = Gat.Text.UserProfile.Request.BORROWER_REQUEST_TITLE.localized().index(of: "@") else {
                    return
                }
                let endText = Gat.Text.UserProfile.Request.BORROWER_REQUEST_TITLE.localized()[Gat.Text.UserProfile.Request.BORROWER_REQUEST_TITLE.localized().index(after: index)..<Gat.Text.UserProfile.Request.BORROWER_REQUEST_TITLE.localized().endIndex]
                guard let endSize = text.stringSize(text: String(endText), with: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)]) else {
                    return
                }
                let location = gesture.location(in: self?.requestTitleLabel)
                guard location.x >= sizeText.width - sizeBookName.width - endSize.width && location.x <= sizeText.width - endSize.width else {
                    return
                }
                self?.controller?.profileViewController?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.bookRequest.book)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func acceptEvent() -> Observable<(BookRequest, RecordStatus)> {
        return self.acceptButton
            .rx
            .controlEvent(.touchUpInside)
            .flatMapLatest { [weak self] (_) -> Observable<(BookRequest, RecordStatus)> in
                return Observable<(BookRequest, RecordStatus)>
                    .combineLatest(
                        Observable<BookRequest>.from(optional: self?.bookRequest),
                        Observable<RecordStatus>.just(.contacting),
                        resultSelector: { ($0, $1) }
                    )
            }
    }
    
    fileprivate func rejectEvent() -> Observable<(BookRequest, RecordStatus)> {
        return self.rejectButton
            .rx
            .controlEvent(.touchUpInside)
            .flatMapLatest { [weak self] (_) -> Observable<(BookRequest, RecordStatus)> in
                return Observable<(BookRequest, RecordStatus)>
                    .combineLatest(
                        Observable<BookRequest>.from(optional: self?.bookRequest),
                        Observable<RecordStatus>.just(.rejected),
                        resultSelector: { ($0, $1) }
                )
            }
    }
}
