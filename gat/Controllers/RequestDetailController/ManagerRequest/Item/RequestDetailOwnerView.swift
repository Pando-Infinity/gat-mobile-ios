//
//  RequestOwnerView.swift
//  gat
//
//  Created by Vũ Kiên on 07/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class RequestDetailOwnerView: UIView {

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
    fileprivate func request(bookRequest: BookRequest, selectStatus: RecordStatus?) {
        Observable<(BookRequest, RecordStatus)>
            .combineLatest(
                Observable<BookRequest>.just(bookRequest),
                Observable<RecordStatus>.from(optional: selectStatus),
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
                    .update(owner: bookRequest, newStatus: status)
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
            .map { (/*$0 == .onHold ||*/ $0 == .unreturned, $0) }
            .do(onNext: { [weak self] (status, recordStatus) in
                if status {
//                    if recordStatus == .onHold {
//                        self?.messageLabel.text = Gat.Text.OwnerRequestDetail.ON_HOLD_MESSAGE
//                    } else if recordStatus == .unreturned {
//                        self?.messageLabel.text = Gat.Text.OwnerRequestDetail.DID_LOST_MESSAGE
//                    }
                    if recordStatus == .unreturned {
                        self?.messageLabel.text = Gat.Text.OwnerRequestDetail.DID_LOST_MESSAGE.localized()
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
        self.registerCell()
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.bookRequest
            .map { (bookRequest) -> [(RecordStatus, RecordStatus)] in
                guard let recordStatus = bookRequest.recordStatus else {
                    return []
                }
                switch recordStatus {
                case .waitConfirm:
                    return [(.waitConfirm, .contacting), (.waitConfirm, .rejected)]
                case .onHold:
                    return [(.onHold, .onHold)]
                case .contacting:
                    return [(.contacting, .contacting), (.contacting, .borrowing), (.contacting, .rejected)]
                case .borrowing:
                    return [(.borrowing, .contacting), (.borrowing, .borrowing), (.borrowing, .completed), (.borrowing, .unreturned)]
                case .unreturned:
                    return  [(.unreturned, .contacting), (.unreturned, .borrowing), (.unreturned, .unreturned)]
                case .completed:
                    return [(.completed, .contacting), (.completed, .borrowing), (.completed, .completed)]
                case .cancelled:
                    return [(.cancelled, .cancelled)]
                case .rejected:
                    return [(.rejected, .rejected)]
                default: return []
                }
            }
            .bind(to: self.tableView.rx.items(cellIdentifier: "infoRequestDetail", cellType: InfoRequestDetailTableViewCell.self))
            { [weak self] (index, status, cell) in
                guard let value = try? self?.bookRequest.value(), let bookRequest = value else {
                    return
                }
                cell.delegate = self
                cell.bookRequest = bookRequest
                cell.selectedStatus = status.1
                switch status.1 {
                case .onHold:
                    cell.actionButton.setTitle(Gat.Text.OwnerRequestDetail.ON_HOLD_STATUS, for: .normal)
                    cell.actionButton.isUserInteractionEnabled = false
                    cell.actionButton.backgroundColor = #colorLiteral(red: 0.4862745098, green: 0.7725490196, blue: 0.462745098, alpha: 1)
                    cell.actionButton.isHidden = true
                    cell.topView.isHidden = true
                    cell.actionView.isHidden = true
                    cell.bottomView.isHidden = true
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultLow
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultHigh
                    break
                case .contacting:
                    cell.actionButton.setTitle(status.0 == .waitConfirm ? Gat.Text.OwnerRequestDetail.ACCEPT_TITLE.localized() : Gat.Text.OwnerRequestDetail.CONTACT_STATUS.localized(), for: .normal)
                    cell.actionButton.isUserInteractionEnabled = status.0 == .waitConfirm
                    cell.actionButton.backgroundColor = status.0 == .waitConfirm ? #colorLiteral(red: 0.5568627451, green: 0.7647058824, blue: 0.8745098039, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.boundView.isHidden = status.0 == .waitConfirm || status.0 == .contacting
                    cell.topView.isHidden = status.0 == .waitConfirm
                    cell.actionView.isHidden = status.0 == .waitConfirm
                    cell.iconImageView.image = #imageLiteral(resourceName: "IconSmallWhiteCheck")
                    cell.bottomView.isHidden = status.0 == .waitConfirm
                    cell.actionLeadingHighConstraint.priority = status.0 == .waitConfirm ? UILayoutPriority.defaultLow : UILayoutPriority.defaultHigh
                    cell.actionLeadingLowConstraint.priority = status.0 == .waitConfirm ? UILayoutPriority.defaultHigh : UILayoutPriority.defaultLow
                    break
                case .borrowing:
                    cell.actionButton.setTitle( Gat.Text.OwnerRequestDetail.BORROW_STATUS.localized(), for: .normal)
                    cell.actionButton.isUserInteractionEnabled = status.0 == .contacting
                    cell.actionButton.backgroundColor = status.0 == .contacting ? #colorLiteral(red: 0.5568627451, green: 0.7647058824, blue: 0.8745098039, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.boundView.isHidden = status.0 == .contacting
                    cell.topView.isHidden = false
                    cell.topView.backgroundColor = status.0 == .contacting ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.actionView.isHidden = false
                    cell.actionView.backgroundColor = status.0 == .contacting ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.iconImageView.image = status.0 == .contacting ? nil : #imageLiteral(resourceName: "IconSmallWhiteCheck")
                    cell.bottomView.isHidden = false
                    cell.bottomView.backgroundColor = status.0 == .contacting ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultHigh
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    break
                case .unreturned:
                    cell.actionButton.setTitle(Gat.Text.OwnerRequestDetail.DID_LOST_STATUS.localized(), for: .normal)
                    cell.actionButton.isUserInteractionEnabled = status.0 == .borrowing
                    cell.actionButton.backgroundColor = status.0 == .borrowing ? #colorLiteral(red: 1, green: 0.4980392157, blue: 0.5176470588, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.boundView.isHidden = true
                    cell.topView.isHidden = false
                    cell.topView.backgroundColor = status.0 == .borrowing ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.actionView.isHidden = false
                    cell.actionView.backgroundColor = status.0 == .borrowing ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.iconImageView.image = status.0 == .borrowing ? nil : #imageLiteral(resourceName: "IconSmallWhiteCancel")
                    cell.bottomView.isHidden = true
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultHigh
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    break
                case .completed:
                    cell.actionButton.setTitle(Gat.Text.OwnerRequestDetail.RETURN_STATUS.localized(), for: .normal)
                    cell.actionButton.isUserInteractionEnabled = status.0 == .borrowing
                    cell.actionButton.backgroundColor = status.0 == .borrowing ? #colorLiteral(red: 0.5568627451, green: 0.7647058824, blue: 0.8745098039, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.boundView.isHidden = status.0 == .borrowing
                    cell.topView.isHidden = false
                    cell.topView.backgroundColor = status.0 == .borrowing ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.actionView.isHidden = false
                    cell.actionView.backgroundColor = status.0 == .borrowing ? #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1) : #colorLiteral(red: 0.3254901961, green: 0.5882352941, blue: 0.7254901961, alpha: 1)
                    cell.iconImageView.image = status.0 == .borrowing ? nil : #imageLiteral(resourceName: "IconSmallWhiteCheck")
                    cell.bottomView.isHidden = status.0 == .completed
                    cell.bottomView.backgroundColor = #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1)
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultHigh
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    break
                case .cancelled:
                    cell.actionButton.setTitle(Gat.Text.OwnerRequestDetail.CANCELLED_STATUS.localized(), for: .normal)
                    cell.actionButton.isUserInteractionEnabled = false
                    cell.boundView.isHidden = true
                    cell.topView.isHidden = true
                    cell.actionButton.backgroundColor = #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.actionView.isHidden = false
                    cell.actionView.backgroundColor = #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.iconImageView.image = #imageLiteral(resourceName: "IconSmallWhiteCancel")
                    cell.bottomView.isHidden = true
                    cell.actionLeadingHighConstraint.priority = UILayoutPriority.defaultHigh
                    cell.actionLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    break
                case .rejected:
                    cell.actionButton.setTitle(status.0 == .rejected ? Gat.Text.OwnerRequestDetail.REJECTED_STATUS.localized() : Gat.Text.OwnerRequestDetail.REJECT_STATUS.localized(), for: .normal)
                    cell.actionButton.isUserInteractionEnabled = status.0 == .waitConfirm || status.0 == .contacting
                    cell.actionButton.backgroundColor = status.0 == .waitConfirm || status.0 == .contacting ? #colorLiteral(red: 1, green: 0.4980392157, blue: 0.5176470588, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1)
                    cell.boundView.isHidden = true
                    cell.topView.isHidden = status.0 == .waitConfirm || status.0 == .rejected
                    cell.topView.backgroundColor = status.0 == .rejected ? #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1) : #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1)
                    cell.actionView.isHidden = status.0 == .waitConfirm
                    cell.actionView.backgroundColor = status.0 == .rejected ?  #colorLiteral(red: 0.9294117647, green: 0.1098039216, blue: 0.1411764706, alpha: 1) : #colorLiteral(red: 0.8431372549, green: 0.8431372549, blue: 0.8431372549, alpha: 1)
                    cell.iconImageView.image = status.0 == .rejected ? #imageLiteral(resourceName: "IconSmallWhiteCancel") : nil
                    cell.bottomView.isHidden = true
                    cell.actionLeadingHighConstraint.priority = status.0 == .waitConfirm ? UILayoutPriority.defaultLow : UILayoutPriority.defaultHigh
                    cell.actionLeadingLowConstraint.priority = status.0 == .waitConfirm ? UILayoutPriority.defaultHigh : UILayoutPriority.defaultLow
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

extension RequestDetailOwnerView: InfoRequestDetailDelegate {
    func handleActionButton(bookRequest: BookRequest, selectStatus: RecordStatus?) {
        if selectStatus == .contacting || selectStatus == .borrowing || selectStatus == .completed {
            self.request(bookRequest: bookRequest, selectStatus: selectStatus)
        } else {
            guard let topViewController = UIApplication.shared.topMostViewController() else {
                return
            }
            
            let okAction = ActionButton(titleLabel: selectStatus == .rejected ? Gat.Text.CommonError.YES_ALERT_TITLE.localized() : Gat.Text.CommonError.LOST_ALERT_TITLE.localized()) { [weak self] in
                self?.request(bookRequest: bookRequest, selectStatus: selectStatus)
            }
            
            let noAction = ActionButton(titleLabel: selectStatus == .rejected ? Gat.Text.CommonError.NO_ALERT_TITLE.localized() : Gat.Text.CommonError.SKIP_ALERT_TITLE.localized(), action: nil)
            
            AlertCustomViewController.showAlert(
                title:
                selectStatus == .rejected ? Gat.Text.CommonError.REJECT_ERROR_TITLE.localized() : Gat.Text.CommonError.LOST_ALERT_TITLE.localized(),
                message: selectStatus == .rejected ? Gat.Text.CommonError.REJECT_MESSAGE.localized() : Gat.Text.CommonError.LOST_BOOK_MESSAGE.localized(),
                actions: [okAction, noAction],
                in: topViewController
            )
        }
        
    }
    
    
}

extension RequestDetailOwnerView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width / 7.0
    }
}
