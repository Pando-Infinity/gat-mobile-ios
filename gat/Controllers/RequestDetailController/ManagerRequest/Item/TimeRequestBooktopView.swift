//
//  TimeRequestView.swift
//  gat
//
//  Created by Vũ Kiên on 16/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol TimeRequestBookstopDelegate: class {
    func updateInstance(bookRequest: BookRequest, sharingStatus: SharingStatus)
}

class TimeRequestBooktopView: UIView {

    @IBOutlet weak var mesageLabel: UILabel!
    @IBOutlet weak var titleLabel: UIButton!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var borrowDateLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var borrowDateButton: UIButton!
    @IBOutlet weak var showImageView: UIImageView!
    
    weak var delegate: TimeRequestBookstopDelegate?
    let instance: BehaviorSubject<Instance> = .init(value: Instance())
    fileprivate let chooseTime: BehaviorSubject<ExpectedTime> = .init(value: .aWeek)
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func `return`(instance: Instance) {
        guard Status.reachable.value else { return }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.isUserInteractionEnabled = false
        
        InstanceNetworkService.shared
            .update(requestTo: instance)
            .catchError({ [weak self] (error) -> Observable<BookRequest> in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.isUserInteractionEnabled = true
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            })
            .do(onNext: { [weak self] (bookRequest) in
                self?.delegate?.updateInstance(bookRequest: bookRequest, sharingStatus: .selfManagerAndAvailable)
            })
            .flatMapLatest { Repository<BookRequest, BookRequestObject>.shared.save(object: $0) }
            .subscribe(onNext: { [weak self] (_) in
                self?.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    func setupUI() {
        self.instance
            .filter { $0.id != 0 }
            .subscribe(onNext: { [weak self] (instance) in
                if instance.sharingStatus == .selfManagerAndAvailable {
                    self?.startBorrow(instance: instance)
                } else if instance.sharingStatus == .selfManagerAndNotAvailable {
                    if let borrower = instance.borrower {
                        if borrower.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                            self?.endBorrow(instance: instance)
                        } 
                    }
                }
            })
            .disposed(by: self.disposeBag)
        
        self.chooseTime
            .map { String(format: Gat.Text.RequestBookstop.EXPECTATION_TIME_TITLE.localized(), $0.toString) }
            .subscribe(self.borrowDateButton.rx.title(for: .normal))
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func startBorrow(instance: Instance) {
        self.layoutIfNeeded()
        self.borrowDateButton.cornerRadius(radius: 10.0)
        self.borrowDateButton.isHidden = false
        self.showImageView.isHidden = false
        self.startDateLabel.isHidden = true
        self.borrowDateLabel.isHidden = true
        self.setupAction(title: Gat.Text.RequestBookstop.START_TITLE.localized(), color: #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1))
    }
    
    fileprivate func endBorrow(instance: Instance) {
        self.borrowDateButton.isHidden = true
        self.showImageView.isHidden = true
        self.startDateLabel.isHidden = false
        self.borrowDateLabel.isHidden = false
        self.setupAction(title: Gat.Text.RequestBookstop.BORROW_TITLE.localized(), color: #colorLiteral(red: 0.9647058824, green: 0.5882352941, blue: 0.4745098039, alpha: 1))
        if let date = instance.request?.borrowTime {
            self.startDateLabel.text = Gat.Text.RequestBookstop.START_BORROW_TITLE.localized() + AppConfig.sharedConfig.stringFormatter(from: date, format: LanguageHelper.language == .japanese ? "yyyy/MM/dd" : "dd/MM/yyyy")
            self.mesageLabel.text = Gat.Text.RequestBookstop.BORROW_BOOK.localized()
        }
        if let date = instance.request?.completeTime {
            self.borrowDateLabel.text = Gat.Text.RequestBookstop.EXPECTATION_TIME.localized() + AppConfig.sharedConfig.stringFormatter(from: date, format: LanguageHelper.language == .japanese ? "yyyy/MM/dd" : "dd/MM/yyyy")
            self.mesageLabel.text = Gat.Text.RequestBookstop.YOU_BORROWING_MESSAGE.localized()

        } else if let expected = instance.request?.borrowExpectation, let date = instance.request?.borrowTime {
            var duration = 0.0
            switch expected {
            case .threeDays: duration = 3600.0 * 24.0 * 3.0
            case .aWeek: duration = 3600.0 * 24.0 * 7
            case .twoWeeks: duration = 3600.0 * 24.0 * 14
            case .threeWeeks: duration = 3600.0 * 24.0 * 21
            case .aMonth: duration = 3600.0 * 24.0 * 30
            }
            self.borrowDateLabel.text = Gat.Text.RequestBookstop.EXPECTATION_TIME.localized() + AppConfig.sharedConfig.stringFormatter(from: date.addingTimeInterval(duration), format: LanguageHelper.language == .japanese ? "yyyy/MM/dd" : "dd/MM/yyyy")
            self.mesageLabel.text = Gat.Text.RequestBookstop.YOU_BORROWING_MESSAGE.localized()
        }
        
        
    }
    
    fileprivate func setupAction(title: String, color: UIColor) {
        self.actionButton.setTitle(title, for: .normal)
        self.actionButton.setTitleColor(color, for: .normal)
        self.actionButton.layer.borderColor = color.cgColor
        self.actionButton.layer.borderWidth = 1.5
        self.actionButton.cornerRadius(radius: 10.0)
    }
    
    
    fileprivate func showAlertReturn(instance: Instance) {
        let yesAction = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized()) { [weak self] in
            self?.return(instance: instance)
        }
        
        let noAction = ActionButton.init(titleLabel: Gat.Text.CommonError.NO_ALERT_TITLE.localized(), action: nil)
        guard let topViewController = UIApplication.shared.topMostViewController() else {
            return
        }
        AlertCustomViewController.showAlert(title: Gat.Text.RequestBorrowerBookstop.CONFIRM.localized(), message: Gat.Text.RequestBorrowerBookstop.RETURN_MESSAGE.localized(), actions: [yesAction, noAction], in: topViewController)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.borrowDateButtonEvent()
        self.actionEvent()
    }
    
    fileprivate func borrowDateButtonEvent() {
        self.borrowDateButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.chooseTime)
            .flatMapLatest { (chooseTime) -> Observable<Int> in
                return Observable<Int>.create({ (observer) -> Disposable in
                    SLPickerView.showTextPickerView(withValues: NSMutableArray(array: ExpectedTime.all.map { $0.toString }), withSelected: ExpectedTime.all[chooseTime.rawValue].toString, completionBlock: { (selected) in
                        let choose = ExpectedTime.all.map { $0.toString }.index(of: selected ?? "") ?? 1
                        observer.onNext(choose)
                    })
                    return Disposables.create()
                })
            }
            .map { ExpectedTime(rawValue: $0)! }
            .subscribe(self.chooseTime)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func actionEvent() {
        self.sendRequest()
        self.returnBookEvent()
    }
    
    fileprivate func sendRequest() {
        self.actionButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.instance)
            .filter { $0.sharingStatus == .selfManagerAndAvailable }
            .flatMapLatest { [weak self] (instance) -> Observable<(Instance, ExpectedTime)> in
                return Observable<(Instance, ExpectedTime)>
                    .combineLatest(Observable<Instance>.just(instance), self?.chooseTime ?? Observable.empty(), resultSelector: { ($0, $1) })
            }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.isUserInteractionEnabled = false
            })
            .flatMapLatest({ [weak self] (instance, expectation) -> Observable<BookRequest> in
                return InstanceNetworkService
                    .shared
                    .create(requestTo: instance, in: expectation)
                    .catchError({ [weak self] (error) -> Observable<BookRequest> in
                        self?.isUserInteractionEnabled = true
                        HandleError.default.showAlert(with: error)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return Observable.empty()
                    })
            })
            .do(onNext: { (request) in
                request.borrower = Repository<UserPrivate, UserPrivateObject>.shared.get()?.profile
            })
            .do(onNext: { [weak self] (bookRequest) in
                self?.delegate?.updateInstance(bookRequest: bookRequest, sharingStatus: .selfManagerAndNotAvailable)
            })
            .flatMapLatest { Repository<BookRequest, BookRequestObject>.shared.save(object: $0) }
            .subscribe(onNext: { [weak self] (_) in
                self?.isUserInteractionEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func returnBookEvent() {
        self.actionButton.rx.tap
            .asObservable()
            .withLatestFrom(self.instance)
            .filter { $0.sharingStatus == .selfManagerAndNotAvailable }
            .subscribe(onNext: { [weak self] (instance) in
                self?.showAlertReturn(instance: instance)
            })
            .disposed(by: self.disposeBag)
    }

}
