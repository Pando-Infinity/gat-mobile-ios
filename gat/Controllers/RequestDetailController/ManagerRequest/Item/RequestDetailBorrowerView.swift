//
//  RequestDetailInfoView.swift
//  gat
//
//  Created by Vũ Kiên on 07/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol RequestDetailDelegate: class {
    func loading(_ isLoading: Bool)
    
    func update()
}

class RequestDetailBorrowerView: UIView {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    
    weak var delegate: RequestDetailDelegate?
    let bookRequest: BehaviorSubject<BookRequest> = .init(value: BookRequest())
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
    }
    
    // MARK: - Request
    fileprivate func request(bookRequest: BookRequest, recordStatus: RecordStatus?) {
        Observable<(BookRequest, RecordStatus)>
            .combineLatest(
                Observable<BookRequest>.just(bookRequest),
                Observable<RecordStatus>.from(optional: recordStatus),
                resultSelector: { ($0, $1) }
            )
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.delegate?.loading(true)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest { [weak self] (bookRequest, status) -> Observable<()> in
                return RequestNetworkService
                    .shared
                    .update(borrower: bookRequest, newStatus: status)
                    .catchError({ [weak self] (error) -> Observable<()> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error, action: { [weak self] in
                            self?.delegate?.update()
                            self?.delegate?.loading(false)
                        })
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.delegate?.update()
                self?.delegate?.loading(false)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.bookRequest
            .map { $0.recordStatus }
            .map { ($0 == .onHold || $0 == .unreturned, $0) }
            .do(onNext: { [weak self] (status, recordStatus) in
                if status {
                    if recordStatus == .onHold {
                        self?.messageLabel.text = Gat.Text.BorrowerRequestDetail.ON_HOLD_MESSAGE.localized()
                    } else if recordStatus == .unreturned {
                        self?.messageLabel.text = Gat.Text.BorrowerRequestDetail.DID_LOST_MESSAGE.localized()
                    }
                    if recordStatus == .unreturned {
                        self?.messageLabel.text = Gat.Text.BorrowerRequestDetail.DID_LOST_MESSAGE.localized()
                    }
                } else {
                    self?.messageLabel.text = ""
                }
            })
            .map{ (status, _) in !status }
            .subscribe(self.messageLabel.rx.isHidden)
            .disposed(by: self.disposeBag)
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.registerCell()
        self.bookRequest
            .map { (bookRequest) -> [(RecordStatus, RecordStatus)] in
                guard let status = bookRequest.recordStatus else {
                    return []
                }
                switch status {
                case .waitConfirm:
                    return [(.waitConfirm, .cancelled)]
                case .onHold:
                    return [(.onHold, .onHold), (.onHold, .cancelled)]
                case .contacting:
                    return [(.contacting, .contacting), (.contacting, .cancelled)]
                case .borrowing:
                    return [(.borrowing, .contacting), (.borrowing, .borrowing)]
                case .completed:
                    return [(.completed, .contacting), (.completed, .borrowing), (.completed, .completed)]
                case .rejected:
                    return [(.rejected, .rejected)]
                case .cancelled:
                    return [(.cancelled, .cancelled)]
                case .unreturned:
                    return [(.unreturned, .contacting), (.unreturned, .borrowing), (.unreturned, .unreturned)]
                default: return []
                }
            }
            .bind(to: self.tableView.rx.items(cellIdentifier: "infoRequestDetail", cellType: InfoRequestDetailTableViewCell.self))
            { [weak self] (index, status, cell) in
                guard let value = try? self?.bookRequest.value(), let bookRequest = value else {
                    return
                }
                cell.bookRequest = bookRequest
                cell.delegate = self
                cell.actionButton.isUserInteractionEnabled = status.0 == .onHold || status.0 == .waitConfirm || status.0 == .contacting
                if status.0 == .onHold || status.0 == .waitConfirm || status.0 == .contacting {
                    cell.selectedStatus = .cancelled
                }
                switch status.1 {
                case .onHold:
                    cell.actionButton.setTitle(Gat.Text.BorrowerRequestDetail.ON_HOLD_STATUS, for: .normal)
                    cell.actionButton.backgroundColor = #colorLiteral(red: 0.4862745098, green: 0.7725490196, blue: 0.462745098, alpha: 1)
                    cell.boundView.isHidden = true
                    cell.topView.isHidden = true
                    cell.actionView.isHidden = true
                    cell.bottomView.isHidden = true
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultHigh
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultLow
                    break
                case .contacting:
                    cell.actionButton.setTitle(Gat.Text.BorrowerRequestDetail.CONTACT_STATUS.localized(), for: .normal)
                    cell.actionButton.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.boundView.isHidden = false
                    cell.topView.isHidden = false
                    cell.actionView.isHidden = false
                    cell.actionView.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.iconImageView.image = #imageLiteral(resourceName: "IconSmallWhiteCheck")
                    cell.bottomView.isHidden = false
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    cell.actionLeadingHighConstraint.priority =  UILayoutPriority.defaultHigh
                    break
                case .borrowing:
                    cell.actionButton.setTitle(Gat.Text.BorrowerRequestDetail.BORROW_STATUS.localized(), for: .normal)
                    cell.actionButton.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.boundView.isHidden = false
                    cell.topView.isHidden = false
                    cell.topView.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.actionView.isHidden = false
                    cell.actionView.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.iconImageView.image = #imageLiteral(resourceName: "IconSmallWhiteCheck")
                    cell.bottomView.isHidden = status.0 == .borrowing
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultHigh
                    break
                case .completed:
                    cell.actionButton.setTitle(Gat.Text.BorrowerRequestDetail.RETURN_STATUS.localized(), for: .normal)
                    cell.actionButton.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.boundView.isHidden = false
                    cell.topView.isHidden = false
                    cell.topView.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.actionView.isHidden = false
                    cell.actionView.backgroundColor = #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.iconImageView.image = #imageLiteral(resourceName: "IconSmallWhiteCheck")
                    cell.bottomView.isHidden = true
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultHigh
                    break
                case .rejected:
                    cell.actionButton.setTitle( Gat.Text.BorrowerRequestDetail.BEING_REJECTED_STATUS.localized(), for: .normal)
                    cell.actionButton.backgroundColor = #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.boundView.isHidden = true
                    cell.topView.isHidden = true
                    cell.actionView.isHidden = false
                    cell.actionView.backgroundColor = #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.iconImageView.image = #imageLiteral(resourceName: "IconSmallWhiteCancel")
                    cell.bottomView.isHidden = true
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultHigh
                    break
                case .cancelled:
                   cell.actionButton.setTitle(Gat.Text.BorrowerRequestDetail.CANCEL_STATUS.localized(), for: .normal)
                   cell.actionButton.backgroundColor = status.0 == .onHold || status.0 == .waitConfirm || status.0 == .contacting ? #colorLiteral(red: 1, green: 0.4980392157, blue: 0.5176470588, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                   cell.boundView.isHidden = true
                   cell.topView.isHidden = status.0 == .onHold || status.0 == .waitConfirm || status.0 == .cancelled
                   cell.topView.backgroundColor = status.0 == .contacting ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                   cell.actionView.isHidden = status.0 == .onHold || status.0 == .waitConfirm
                   cell.actionView.backgroundColor = status.0 == .contacting ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                   cell.iconImageView.image = status.0 == .contacting ? nil : #imageLiteral(resourceName: "IconSmallWhiteCancel")
                   cell.bottomView.isHidden = true
                   cell.actionLeadingLowConstraint.priority = status.0 == .onHold || status.0 == .waitConfirm ? UILayoutPriority.defaultHigh : UILayoutPriority.defaultLow
                   cell.actionLeadingHighConstraint.priority = status.0 == .onHold || status.0 == .waitConfirm ? UILayoutPriority.defaultLow : UILayoutPriority.defaultHigh
                   break
                case .unreturned:
                    cell.actionButton.setTitle(Gat.Text.BorrowerRequestDetail.DID_LOST_STATUS.localized(), for: .normal)
                    cell.actionButton.backgroundColor = #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.boundView.isHidden = true
                    cell.topView.isHidden = false
                    cell.topView.backgroundColor = #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.actionView.isHidden = false
                    cell.actionView.backgroundColor = #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.iconImageView.image = #imageLiteral(resourceName: "IconSmallWhiteCancel")
                    cell.bottomView.isHidden = true
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultHigh
                    break
                default:
                    break
                }
            }
            .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func registerCell() {
        let nib = UINib(nibName: "InfoRequestDetailCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "infoRequestDetail")
    }
}

extension RequestDetailBorrowerView: InfoRequestDetailDelegate {
    func handleActionButton(bookRequest: BookRequest, selectStatus: RecordStatus?) {
        guard let viewController = UIApplication.shared.topMostViewController() else {
            return
        }
        let okAction = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized()) { [weak self] in
            self?.request(bookRequest: bookRequest, recordStatus: selectStatus)
        }
        let cancelAction = ActionButton(titleLabel: Gat.Text.CommonError.NO_ALERT_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.CANCEL_REQUEST_ERROR_TITLE.localized(), message: Gat.Text.CommonError.CANCEL_REQUEST_MESSAGE.localized(), actions: [okAction, cancelAction], in: viewController)
    }
    
    
}

extension RequestDetailBorrowerView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width / 7.0
    }
}
