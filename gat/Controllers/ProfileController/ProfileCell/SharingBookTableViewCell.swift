//
//  SharingBookTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 09/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import RxSwift
import RxCocoa

protocol SharingBookCellDelegate: class {
//    func change(instance: Instance, status: SharingStatus)
    
    func changeScene(identifier: String, sender: Any?)
}

class SharingBookTableViewCell: UITableViewCell {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var borrowSwitch: UISwitch!
    @IBOutlet weak var borrowTitleLabel: UILabel!
    @IBOutlet weak var forwardImageView: UIImageView!
    @IBOutlet weak var borrowLabel: UILabel!
    
    weak var delegate: SharingBookCellDelegate?
    fileprivate var instance: Instance!
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.event()
    }
    
    //MARK: - UI
    func setup(instance: Instance) {
        self.instance = instance
        self.setup(bookInfo: instance.book)
        self.borrowTitleLabel.text = Gat.Text.UserProfile.BookInstance.BORROW_STATUS_TITLE.localized()
        self.setupSharingStatus(of: instance)
    }
    
    fileprivate func setup(bookInfo: BookInfo) {
        self.bookImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookInfo.imageId))!, placeholderImage: DEFAULT_BOOK_ICON)
        self.nameLabel.text = bookInfo.title
        self.authorLabel.text = bookInfo.author
        self.setupRateView(with: bookInfo.rateAvg)
    }
    
    fileprivate func setupRateView(with rating: Double) {
        self.layoutIfNeeded()
        self.rateView.rating = rating
        self.rateView.text = String(format: "%.2f", rating)
        self.rateView.settings.starSize = Double(self.rateView.frame.height)
    }
    
    fileprivate func setupSharingStatus(of instance: Instance) {
        self.borrowSwitch.isHidden = true
        self.borrowTitleLabel.isHidden = true
        guard let sharingStatus = instance.sharingStatus else {
            self.borrowSwitch.isOn = false
            self.borrowSwitch.isHidden = true
            self.borrowTitleLabel.isHidden = false
            self.forwardImageView.isHidden = true
            self.borrowLabel.isHidden = true
            return
        }
        switch sharingStatus {
        case .notSharing:
            self.borrowSwitch.isOn = false
            self.borrowSwitch.isHidden = true
            self.borrowTitleLabel.isHidden = true
            self.forwardImageView.isHidden = true
            self.borrowLabel.isHidden = true
            break
        case .sharing:
            self.borrowSwitch.isOn = true
            self.borrowSwitch.isHidden = true
            self.borrowTitleLabel.isHidden = true
            self.forwardImageView.isHidden = true
            self.borrowLabel.isHidden = true
            break
        case .borrowing:
//            self.borrowSwitch.isHidden = true
//            self.borrowTitleLabel.isHidden = true
            self.forwardImageView.isHidden = false
            self.borrowLabel.isHidden = false
            self.setupTitleBorrower(borrower: instance.borrower?.name ?? "")
            break
        case .lost:
//            self.borrowSwitch.isHidden = true
//            self.borrowTitleLabel.isHidden = true
            self.forwardImageView.isHidden = true
            self.borrowLabel.isHidden = true
            break
        default:
            break
        }
    }
    
    fileprivate func setupTitleBorrower(borrower: String) {
        let text = String(format: Gat.Text.UserProfile.BookInstance.BORROW_BY_TITLE.localized(), borrower)
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)], range: (text as NSString).range(of: borrower))
        self.borrowLabel.attributedText = attributedText
    }
    
    //MARK: - Event
    fileprivate func event() {
//        self.statusSharingChangedEvent()
        self.imageViewEvent()
        self.borrowerLabelEvent()
    }
    
//    fileprivate func statusSharingChangedEvent() {
//        self.borrowSwitch
//            .rx
//            .controlEvent(.valueChanged)
//            .flatMapLatest { [weak self] (_) -> Observable<Bool> in
//                return Observable<Bool>.from(optional: self?.borrowSwitch.isOn)
//            }
//            .delay(0.5, scheduler: MainScheduler.instance)
//            .flatMapLatest { [weak self] (status) -> Observable<(Instance, Bool)> in
//                return Observable<(Instance, Bool)>
//                    .combineLatest(
//                        Observable<Instance>.from(optional: self?.instance),
//                        Observable<Bool>.just(status),
//                        resultSelector: { ($0, $1) }
//                    )
//            }
//            .filter { _ in Status.reachable.value }
//            .do(onNext: { [weak self] (instance, status) in
//                UIApplication.shared.isNetworkActivityIndicatorVisible = true
//                instance.sharingStatus = SharingStatus(rawValue: status.hashValue)
//                self?.delegate?.change(instance: instance, status: SharingStatus(rawValue: status.hashValue)!)
//            })
//            .flatMapLatest { [weak self] (instance, status) in
//                Observable<((), Instance)>
//                    .combineLatest(
//                        InstanceNetworkService
//                            .shared
//                            .change(instance: instance, with: status)
//                            .catchError { (error) -> Observable<()> in
//                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                                instance.sharingStatus = SharingStatus(rawValue: (!status).hashValue)
//                                self?.delegate?.change(instance: instance, status: SharingStatus(rawValue: (!status).hashValue)!)
//                                HandleError.default.showAlert(with: error)
//                                return Observable<()>.empty()
//                            },
//                        Observable<Instance>.just(instance),
//                        resultSelector: { ($0, $1) }
//                    )
//            }
//            .do(onNext: { (_) in
//                UIApplication.shared.isNetworkActivityIndicatorVisible = false
//            })
//            .map { (_, instance) in instance }
//            .flatMapLatest { Repository<Instance, InstanceObject>.shared.save(object: $0) }
//            .subscribe()
//            .disposed(by: self.disposeBag)
//    }
    
    fileprivate func imageViewEvent() {
        self.bookImageView
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (gesture) in
                self?.delegate?.changeScene(identifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: self?.instance.book)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func borrowerLabelEvent() {
        self.borrowLabel
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (gesture) in
                guard let borrowerName = self?.instance.borrower?.name, let text = self?.borrowTitleLabel.text, let sizeBorrower = self?.borrowLabel.text?.stringSize(text: borrowerName, with: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)]), let sizeText = self?.borrowTitleLabel.text?.stringSize(text: text, with: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)]) else {
                    return
                }
                let location = gesture.location(in: self?.borrowLabel)
                guard location.x >= sizeText.width - sizeBorrower.width else {
                    return
                }
                guard let profile = self?.instance.borrower else { return }
                let userPublic = UserPublic()
                userPublic.profile = profile
                self?.delegate?.changeScene(identifier: Gat.Segue.openVisitorPage, sender: userPublic)
            }
            .disposed(by: self.disposeBag)
    }
}
