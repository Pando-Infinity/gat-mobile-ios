//
//  BookstopTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 04/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol BookstopCellDelegate: class {
    func showBookstopOrganization(identifier: String, sender: Any?)
}

class BookstopTableViewCell: UITableViewCell {

    @IBOutlet weak var bookstopImageView: UIImageView!
    @IBOutlet weak var bookstopNameLabel: UILabel!
    @IBOutlet weak var bookstopAddressLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var wattingLabel: UILabel!
    
    weak var delegate: BookstopCellDelegate?
    weak var editInfoController: EditInfoUserViewController?
    fileprivate var bookstop: Bookstop?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
    }
    
    // MARK: - Data
    fileprivate func sendRequest(bookstop: Bookstop, requestStatus: RequestBookstopStatus) {
        Observable<(Bookstop, RequestBookstopStatus)>
            .combineLatest(
                Observable<Bookstop>.just(bookstop),
                Observable<RequestBookstopStatus>.just(requestStatus),
                resultSelector: { ($0, $1) }
            )
            .filter { _ in Status.reachable.value }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .request(in: $0, with: $1)
                    .catchError { (error) -> Observable<()> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .flatMapLatest { _ in
                UserNetworkService
                    .shared
                    .privateInfo()
                    .catchError({ (error) -> Observable<UserPrivate> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
            .flatMap {
                Observable<UserPrivate>
                    .combineLatest(
                        Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                        Observable<UserPrivate>.just($0),
                        resultSelector: { (old, new) -> UserPrivate in
                            old.update(new: new)
                            return old
                    })

            }
            .do(onNext: { [weak self] (userPrivate) in
                self?.editInfoController?.user = userPrivate
                self?.editInfoController?.user.bookstops = userPrivate.bookstops.filter { ($0.kind as? BookstopKindOrganization)?.status != nil }
                self?.editInfoController?.tableView.reloadData()
            })
            .flatMapLatest { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .subscribe(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - UI
    func setup(bookstop: Bookstop) {
        self.bookstop = bookstop
        self.setupProfile(bookstop.profile!)
        if let status = (bookstop.kind as? BookstopKindOrganization)?.status {
            self.setupAction(status: status)
        }
        
    }
    
    func setupProfile(_ profile: Profile) {
        self.setupImage(id: profile.imageId)
        self.bookstopNameLabel.text = profile.name
        self.bookstopAddressLabel.text = profile.address
    }
    
    fileprivate func setupImage(id: String) {
        self.bookstopImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: id))!, placeholderImage: DEFAULT_USER_ICON)
        self.layoutIfNeeded()
        self.bookstopImageView.circleCorner()
        self.bookstopImageView.layer.borderColor = #colorLiteral(red: 0.5568627451, green: 0.7647058824, blue: 0.8745098039, alpha: 1)
        self.bookstopImageView.layer.borderWidth = 1.0
    }
    
    fileprivate func setupAction(status: UserBookstopStatus) {
        switch status {
        case .waitting:
            self.wattingLabel.isHidden = false
            self.wattingLabel.text = Gat.Text.EditUser.CANCEL_REQUEST_TITLE.localized()
            self.actionButton.setImage(#imageLiteral(resourceName: "cancel-orange-icon"), for: .normal)
            self.actionButton.setTitle("", for: .normal)
            self.actionButton.tintColor = #colorLiteral(red: 0.9647058824, green: 0.5882352941, blue: 0.4745098039, alpha: 1)
            self.actionButton.layer.borderColor = UIColor.clear.cgColor
            break
        case .accepted:
            self.wattingLabel.isHidden = true
            self.actionButton.setImage(nil, for: .normal)
            self.actionButton.setTitle(Gat.Text.EditUser.REMOVE_TITLE.localized(), for: .normal)
            self.actionButton.cornerRadius(radius: 7.5)
            self.actionButton.layer.borderColor = #colorLiteral(red: 0.9647058824, green: 0.5882352941, blue: 0.4745098039, alpha: 1)
            self.actionButton.layer.borderWidth = 1.5
            break
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.actionEvent()
        self.showBookstop()
    }
    
    fileprivate func actionEvent() {
        guard self.actionButton != nil else {
            return
        }
        self.actionButton
            .rx
            .tap
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                guard let bookstop = self?.bookstop, let status = (self?.bookstop?.kind as? BookstopKindOrganization)?.status, let vc = UIApplication.shared.topMostViewController() else {
                    return
                }
                let cancel = ActionButton(titleLabel: Gat.Text.CommonError.NO_ALERT_TITLE.localized(), action: nil)
                switch status {
                case .waitting:
                    let ok = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: { [weak self] in
                        self?.sendRequest(bookstop: bookstop, requestStatus: .cancel)
                    })
                    AlertCustomViewController.showAlert(title: Gat.Text.CommonError.CANCEL_NOTIFICATION_ALERT_TITLE.localized(), message: String(format: Gat.Text.CommonError.CANCEL_REQUEST_BOOKSTOP_MESSAGE.localized(), bookstop.profile!.name), actions: [ok, cancel], in: vc)
                    break
                case .accepted:
                    let ok = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: { [weak self] in
                        self?.sendRequest(bookstop: bookstop, requestStatus: .leave)
                    })
                    AlertCustomViewController.showAlert(title: Gat.Text.CommonError.CANCEL_NOTIFICATION_ALERT_TITLE.localized(), message: String(format: Gat.Text.CommonError.LEVEAVE_BOOKSTOP_MESSAGE.localized(), bookstop.profile!.name), actions: [ok, cancel], in: vc)
                    break
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showBookstop() {
        self.bookstopImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .flatMapLatest { [weak self] (_) -> Observable<Bookstop> in
                return Observable<Bookstop>.from(optional: self?.bookstop)
            }
            .subscribe(onNext: { [weak self] (bookstop) in
                self?.delegate?.showBookstopOrganization(identifier: "showBookstopOrganization", sender: bookstop)
            })
            .disposed(by: self.disposeBag)
    }

}
