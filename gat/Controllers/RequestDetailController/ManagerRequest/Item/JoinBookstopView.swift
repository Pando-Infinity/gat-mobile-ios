//
//  JoinBookstopView.swift
//  gat
//
//  Created by Vũ Kiên on 12/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol JoinBookstopDelegate: class {
    func showJoin(viewController: UIViewController)
    
    func updateInstance()
}

class JoinBookstopView: UIView {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    
    weak var delegate: JoinBookstopDelegate?
    let bookstop: BehaviorSubject<Bookstop> = .init(value: Bookstop())
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.request()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Request
    fileprivate func request() {
        self.joinEvent()
            .filter {$0.memberType == .open }
            .flatMapLatest { [weak self] (bookstop) -> Observable<Bookstop> in
                return Repository<Bookstop, BookstopObject>
                    .shared
                    .getAll()
                    .map({ (list) -> Bool in
                        return list.contains(where: {$0.id == bookstop.id })
                    })
                    .do(onNext: { [weak self] (status) in
                        if status {
                            self?.showAlert()
                        }
                    })
                    .filter { !$0 }
                    .map { _ in bookstop }
            }
            .filter { _ in Status.reachable.value }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .map { ($0, RequestBookstopStatus.join) }
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .request(in: $0, with: $1)
                    .catchError { (error) -> Observable<()> in
                        HandleError.default.showAlert(with: error)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return Observable.empty()
                    }
            }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .flatMapLatest({ [weak self] (_) -> Observable<Bookstop> in
                guard let value = try? self?.bookstop.value() else {
                    return Observable.empty()
                }
                return Observable<Bookstop>.from(optional: value)
            })
            .flatMapLatest({ (bookstop) -> Observable<UserPrivate> in
                return Observable<UserPrivate>.combineLatest(Repository<UserPrivate, UserPrivateObject>.shared.getFirst(), Observable<Bookstop>.just(bookstop), resultSelector: { (userPrivate, bookstop) -> UserPrivate in
                    let kind = BookstopKindOrganization()
                    kind.status = .accepted
                    bookstop.kind = kind
                    userPrivate.bookstops.append(bookstop)
                    return userPrivate
                })
            })
            .flatMapLatest { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .subscribe(onNext: { [weak self] (_) in
                self?.delegate?.updateInstance()
            })
            .disposed(by: self.disposeBag)
        
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        
        self.bookstop
            .filter { $0.id != 0 }
            .map { String(format: Gat.Text.RequestBookstop.JOIN_BOOKSTOP_MESSAGE.localized(), $0.profile!.name, $0.profile!.name) }
            .subscribe(self.messageLabel.rx.text)
            .disposed(by: self.disposeBag)
        self.joinButton.cornerRadius(radius: 10.0)
        self.joinButton.layer.borderColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1)
        self.joinButton.layer.borderWidth = 1.5
        self.joinButton.setTitle(Gat.Text.RequestBookstop.JOIN_TITLE.localized(), for: .normal)
    }
    
    fileprivate func showAlert() {
        guard let vc = UIApplication.shared.topMostViewController() else {
            return
        }
        let ok = ActionButton.init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.NOTIFICATION_TITLE.localized(), message: Gat.Text.CommonError.YOUR_SEND_MESSAGE.localized(), actions: [ok], in: vc)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.joinEvent()
            .filter { $0.memberType == .closed }
            .flatMapLatest { [weak self] (bookstop) -> Observable<Bookstop> in
                return Repository<UserPrivate, UserPrivateObject>.shared.getFirst().map { $0.bookstops }
                    .map { $0.first(where: { $0.id == bookstop.id }) }
                    .do(onNext: { [weak self] (bookstop) in
                        if bookstop != nil {
                            self?.showAlert()
                        }
                    })
                    .filter { $0 == nil }
                    .map { _ in bookstop }
            }
            .subscribe(onNext: { [weak self] (bookstop) in
                let storyboard = UIStoryboard(name: "Barcode", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: JoinBarcodeViewController.className) as! JoinBarcodeViewController
                vc.bookstop = bookstop
                self?.delegate?.showJoin(viewController: vc)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func joinEvent() -> Observable<Bookstop> {
        return self.joinButton.rx.tap
            .do(onNext: { (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { Session.shared.isAuthenticated }
            .flatMapLatest { [weak self] (_) -> Observable<Bookstop> in
                guard let value = try? self?.bookstop.value() else {
                    return Observable.empty()
                }
                return Observable<Bookstop>.from(optional: value)
            }
    }

}

extension JoinBookstopView {
    class func size(bookstop: Bookstop, in size: CGSize) -> CGSize {
        let label = UILabel()
        label.text = String(format: Gat.Text.RequestBookstop.JOIN_BOOKSTOP_MESSAGE.localized(), bookstop.profile!.name, bookstop.profile!.name)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 12.0)
        let s = label.sizeThatFits(.init(width: size.width - 32.0, height: .infinity))
        return .init(width: size.width, height: s.height + 16.0 * 3 + 50.0)
    }
}
