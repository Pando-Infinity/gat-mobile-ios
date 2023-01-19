//
//  ListBookstopCollectionViewCell.swift
//  gat
//
//  Created by jujien on 12/7/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ListBookstopCollectionViewCell: UICollectionViewCell {
    class var identifier: String { return "listBookstopCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var actionView: UIView!
    
    fileprivate let disposeBag = DisposeBag()
    let bookstop = BehaviorRelay<Bookstop>(value: .init())
    var actionHandler: ((Bookstop) -> Void)?
    var sizeCell: CGSize = .zero
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.circleCorner()
    }
    
    // MARK: - Data
    fileprivate func sendRequest(requestStatus: RequestBookstopStatus) {
        Observable<(Bookstop, RequestBookstopStatus)>
        .combineLatest(
            self.bookstop,
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
        .do(onNext: { [weak self] (_) in
            if let bookstop = self?.bookstop.value {
                self?.actionHandler?(bookstop)
            }
        })
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
        .flatMapLatest { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
        .subscribe(onNext: { (_) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
        .disposed(by: self.disposeBag)

    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addressLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 32.0 - 158.0
        self.addressLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 32.0 - 158.0
        self.cornerRadius(radius: 10.0)
        self.contentView.cornerRadius(radius: 10.0)
        self.dropShadow(offset: .init(width: 2.0, height: 2.0), radius: 2.0, opacity: 0.5, color: #colorLiteral(red: 0.8078431373, green: 0.7960784314, blue: 0.7960784314, alpha: 1))
        self.bookstop.map { $0.profile!.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.bookstop.map { $0.profile!.address }.bind(to: self.addressLabel.rx.text).disposed(by: self.disposeBag)
        self.bookstop.map { URL.init(string: AppConfig.sharedConfig.setUrlImage(id: $0.profile!.imageId)) }
            .subscribe(onNext: { [weak self] (url) in
                self?.imageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
            })
            .disposed(by: self.disposeBag)
        let status = self.bookstop
            .map { $0.kind as? BookstopKindOrganization }
            .map { $0?.status }.filter { $0 != nil }.map { $0! }
            .share()
        status
            .filter { $0 == .waitting }
            .subscribe(onNext: { [weak self] (_) in
                self?.statusLabel.text = Gat.Text.EditUser.CANCEL_REQUEST_TITLE.localized()
                self?.statusLabel.textColor = #colorLiteral(red: 0.9647058824, green: 0.5882352941, blue: 0.4745098039, alpha: 1)
                self?.statusImageView.image = #imageLiteral(resourceName: "cancel-orange-icon")
            })
            .disposed(by: self.disposeBag)

        status.filter { $0 == .accepted }
            .subscribe(onNext: { [weak self] (_) in
                self?.statusLabel.text = Gat.Text.EditUser.REMOVE_TITLE.localized()
                self?.statusLabel.textColor = #colorLiteral(red: 0.9843137255, green: 0.2862745098, blue: 0.368627451, alpha: 1)
                self?.statusImageView.image = #imageLiteral(resourceName: "leave-bookstop")
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func showAlert() {
        guard let vc = UIApplication.shared.topMostViewController(), let status = (self.bookstop.value.kind as? BookstopKindOrganization)?.status else { return }
        
        let cancel = ActionButton(titleLabel: Gat.Text.CommonError.NO_ALERT_TITLE.localized(), action: nil)
        switch status {
        case .waitting:
            let ok = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: { [weak self] in
                self?.sendRequest(requestStatus: .leave)
            })
            AlertCustomViewController.showAlert(title: Gat.Text.CommonError.CANCEL_NOTIFICATION_ALERT_TITLE.localized(), message: String(format: Gat.Text.CommonError.CANCEL_REQUEST_BOOKSTOP_MESSAGE.localized(), self.bookstop.value.profile!.name), actions: [ok, cancel], in: vc)
            break
        case .accepted:
            let ok = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: { [weak self] in
                self?.sendRequest(requestStatus: .leave)
            })
            AlertCustomViewController.showAlert(title: Gat.Text.CommonError.CANCEL_NOTIFICATION_ALERT_TITLE.localized(), message: String(format: Gat.Text.CommonError.LEVEAVE_BOOKSTOP_MESSAGE.localized(), self.bookstop.value.profile!.name), actions: [ok, cancel], in: vc)
            break
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.actionView.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.showAlert()
            })
            .disposed(by: self.disposeBag)
            
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attribute = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell != .zero {
            attribute.frame.size = self.sizeCell
        }
        return attribute
    }
}
