//
//  RequestDetailBorrowerBookstopView.swift
//  gat
//
//  Created by Vũ Kiên on 13/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol RequestDetailBorrowerBookstopDelegate: class {
    func update()
}

class RequestDetailBorrowerBookstopView: UIView {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    
    weak var delegate: RequestDetailBorrowerBookstopDelegate?
    let bookRequest: BehaviorSubject<BookRequest> = .init(value: BookRequest())
    let instance: BehaviorSubject<Instance?> = .init(value: nil)
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
    }
    
    // Request
    fileprivate func request(bookRequest: BookRequest, status: RecordStatus) {
        Observable.from(optional: try! self.instance.value())
            .filter { $0 != nil }.map { $0! }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.isUserInteractionEnabled = false
            })
            .flatMap { (instance) -> Observable<BookRequest> in
                return InstanceNetworkService.shared.update(requestTo: instance)
                    .catchError { [weak self] (error) -> Observable<BookRequest> in
                        self?.isUserInteractionEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return .empty()
                }
            }
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.isUserInteractionEnabled = true
                self?.delegate?.update()
            })
            .disposed(by: self.disposeBag)
        
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupTableView()
        self.setupMessageLabel()
    }
    
    fileprivate func setupMessageLabel() {
        self.bookRequest
            .filter { $0.recordStatus != nil && $0.requestTime != nil }
            .map { (bookRequest) -> String in
                var dateBorrow: Date!
                switch bookRequest.borrowExpectation {
                case .threeDays:
                    if Date().timeIntervalSince1970 - bookRequest.requestTime!.timeIntervalSince1970 > 3 * 24 * 60 * 60 {
                        return String(format: Gat.Text.RequestBorrowerBookstop.DEADLINE_RETURN_BOOK_MESSAGE.localized(), ExpectedTime.threeDays.toString)
                    }
                    dateBorrow = Date(timeIntervalSince1970: bookRequest.requestTime!.timeIntervalSince1970 + 3 * 24 * 60 * 60)
                    break
                case .aWeek:
                    if Date().timeIntervalSince1970 - bookRequest.requestTime!.timeIntervalSince1970 > 7 * 24 * 60 * 60 {
                        return String(format: Gat.Text.RequestBorrowerBookstop.DEADLINE_RETURN_BOOK_MESSAGE.localized(), ExpectedTime.aWeek.toString)
                    }
                    dateBorrow = Date(timeIntervalSince1970: bookRequest.requestTime!.timeIntervalSince1970 + 7 * 24 * 60 * 60)
                    break
                case .twoWeeks:
                    if Date().timeIntervalSince1970 - bookRequest.requestTime!.timeIntervalSince1970 > 2 * 7 * 24 * 60 * 60 {
                        return String(format: Gat.Text.RequestBorrowerBookstop.DEADLINE_RETURN_BOOK_MESSAGE.localized(), ExpectedTime.twoWeeks.toString)
                    }
                    dateBorrow = Date(timeIntervalSince1970: bookRequest.requestTime!.timeIntervalSince1970 + 2 * 7 * 24 * 60 * 60)
                    break
                case .threeWeeks:
                    if Date().timeIntervalSince1970 - bookRequest.requestTime!.timeIntervalSince1970 > 3 * 7 * 24 * 60 * 60 {
                        return String(format: Gat.Text.RequestBorrowerBookstop.DEADLINE_RETURN_BOOK_MESSAGE.localized(), ExpectedTime.threeWeeks.toString)
                    }
                    dateBorrow = Date(timeIntervalSince1970: bookRequest.requestTime!.timeIntervalSince1970 + 3 * 7 * 24 * 60 * 60)
                    break
                case .aMonth:
                    if Date().timeIntervalSince1970 - bookRequest.requestTime!.timeIntervalSince1970 > 30 * 24 * 60 * 60 {
                        return String(format: Gat.Text.RequestBorrowerBookstop.DEADLINE_RETURN_BOOK_MESSAGE.localized(), ExpectedTime.aMonth.toString)
                    }
                    dateBorrow = Date(timeIntervalSince1970: bookRequest.requestTime!.timeIntervalSince1970 + 30 * 24 * 60 * 60)
                    break
                }
                return String(format: Gat.Text.RequestBorrowerBookstop.EXPECTED_TIME.localized(), AppConfig.sharedConfig.stringFormatter(from: dateBorrow, format: LanguageHelper.language == .japanese ? "yyyy/MM/dd" : "dd/MM/yyyy"))
            }
            .subscribe(self.messageLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        self.bookRequest
            .map { $0.recordStatus == .completed }
            .subscribe(self.messageLabel.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTableView() {
        self.registerCell()
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.bookRequest
            .filter { $0.recordStatus != nil }
            .map { (bookRequest) -> [(RecordStatus, RecordStatus, BookRequest)] in
                switch bookRequest.recordStatus! {
                case .borrowing:
                    return [(.borrowing, .borrowing, bookRequest), (.borrowing, .completed, bookRequest)]
                case .completed:
                    return [(.completed, .borrowing, bookRequest), (.completed, .completed, bookRequest)]
                default:
                    return []
                }
            }
            .bind(to: self.tableView.rx.items(cellIdentifier: "infoRequestBooktopCell", cellType: InfoRequestBookstopTableViewCell.self))
            { [weak self] (index, status, cell) in
                cell.bookRequest = status.2
                cell.delegate = self
                switch status.1 {
                case .borrowing:
                    cell.actionButton.setTitle(Gat.Text.BorrowerRequestDetail.BORROW_STATUS.localized(), for: .normal)
                    cell.actionButton.isUserInteractionEnabled = false
                    cell.actionButton.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.boundView.isHidden = false
                    cell.topView.isHidden = true
                    cell.topView.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.actionView.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.iconImageView.isHidden = false
                    cell.bottomView.isHidden = false
                    cell.dateLabel.isHidden = status.2.requestTime == nil
                    if let date = status.2.requestTime {
                        cell.dateLabel.text = AppConfig.sharedConfig.stringFormatter(from: date, format: LanguageHelper.language == .japanese ? "yyyy/MM/dd" : "dd/MM/yyyy")
                    }
                    break
                case .completed:
                    cell.actionButton.setTitle(Gat.Text.BorrowerRequestDetail.RETURN_STATUS.localized(), for: .normal)
                    cell.actionButton.isUserInteractionEnabled = status.0 == .borrowing
                    cell.actionButton.backgroundColor = status.0 == .borrowing ? #colorLiteral(red: 0.5568627451, green: 0.7647058824, blue: 0.8745098039, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.boundView.isHidden = status.0 == .borrowing
                    cell.topView.isHidden = false
                    cell.topView.backgroundColor = status.0 == .borrowing ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.actionView.backgroundColor = status.0 == .borrowing ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.iconImageView.isHidden = status.0 == .borrowing
                    cell.bottomView.isHidden = true
                    cell.dateLabel.isHidden = status.2.completeTime == nil
                    if let date = status.2.completeTime {
                        cell.dateLabel.text = AppConfig.sharedConfig.stringFormatter(from: date, format: LanguageHelper.language == .japanese ? "yyyy/MM/dd" : "dd/MM/yyyy")
                    }
                    break
                default:
                    break
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func registerCell() {
        let nib = UINib.init(nibName: "InfoRequestBookstopDetailCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "infoRequestBooktopCell")
    }
    
    // MARK: - Event
    
}

extension RequestDetailBorrowerBookstopView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height / 2.0
    }
}

extension RequestDetailBorrowerBookstopView: InfoRequestDetailDelegate {
    func handleActionButton(bookRequest: BookRequest, selectStatus: RecordStatus?) {
        let yesAction = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized()) { [weak self] in
            self?.request(bookRequest: bookRequest, status: selectStatus!)
        }
        
        let noAction = ActionButton.init(titleLabel: Gat.Text.CommonError.NO_ALERT_TITLE.localized(), action: nil)
        guard let topViewController = UIApplication.shared.topMostViewController() else {
            return
        }
        AlertCustomViewController.showAlert(title: Gat.Text.RequestBorrowerBookstop.CONFIRM.localized(), message: Gat.Text.RequestBorrowerBookstop.RETURN_MESSAGE.localized(), actions: [yesAction, noAction], in: topViewController)
    }
    
    
}
