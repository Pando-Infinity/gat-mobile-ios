//
//  TransactionCollectionViewCell.swift
//  gat
//
//  Created by jujien on 05/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class TransactionCollectionViewCell: UICollectionViewCell {
    class var identifier: String { "transactionCell" }
    
    @IBOutlet weak var typeView: UIView!
    @IBOutlet weak var typeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    fileprivate let disposeBag = DisposeBag()
    let transaction = BehaviorRelay<Transaction?>(value: nil)
    var cancelHandler: ((Transaction) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupTitle()
        self.setupSubTitle()
        self.setupAmount()
        self.setupStatus()
        self.setupCancelButton()
        self.setupTypeImage()
    }
    
    fileprivate func setupTitle() {
        self.transaction.compactMap { $0?.type }.map { type in
            switch type {
            case .overdueFee: return "Overdue Fee"
            case .giveDonation: return "Give donation"
            case .receiveDonation: return "Receive Donation"
            case .transferToGAT: return "Transfer to GAT wallet"
            case .borrowBookFee: return "Borrow book fee"
            case .refundBookBorrowFee: return "Refund book borrow fee"
            case .refundDepositFee: return "Refund deposit fee"
            case .extensionFee: return "Extension fee"
            case .refundExtensionFee: return "Refund extension fee"
            case .send: return "Send"
            case .receive: return "Receive"
            case .transferToApp: return "Transfer to app"
            }
        }
        .bind(to: self.titleLabel.rx.text)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSubTitle() {
        let time = self.transaction.compactMap { $0?.date }.map { date in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm, MM/dd"
            return dateFormatter.string(from: date)
        }
        let source = self.transaction.compactMap { $0?.operation }
            .map { operation in
                switch operation {
                case .app: return "From app"
                case .fromUser(let user): return "From \(user.name)"
                case .toUser(let user): return "To \(user.name)"
                case .fromAddress(let address): return "From \(self.showAddress(address))"
                case .toAddress(let address): return "To \(self.showAddress(address))"
                }
            }
        
        Observable<String>.combineLatest(time, source) { text1, text2 in
            return "\(text1) • \(text2)"
        }
        .bind(to: self.subTitleLabel.rx.text)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupAmount() {
        self.transaction.compactMap { $0 }.map { transaction in
            let value = "\(Int(transaction.amount)) GAT"
            if transaction.type == .giveDonation || transaction.type == .transferToGAT || transaction.type == .borrowBookFee || transaction.type == .extensionFee || transaction.type == .overdueFee || transaction.type == .send || transaction.type == .transferToApp {
                return "- \(value)"
            }
            return "+ \(value)"
        }
        .bind(to: self.amountLabel.rx.text)
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupStatus() {
        self.transaction.compactMap { transaction in
            return transaction?.status
        }
        .map { (status) in
            switch status {
            case Transaction.TransactionStatus.success: return NSAttributedString(string: "Success", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: #colorLiteral(red: 0.3921568627, green: 0.8588235294, blue: 0.5333333333, alpha: 1)])
            case Transaction.TransactionStatus.processing: return NSAttributedString(string: "Proccessing", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: #colorLiteral(red: 1, green: 0.7215686275, blue: 0, alpha: 1)])
            case Transaction.TransactionStatus.canceled: return NSAttributedString(string: "Canceled", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: #colorLiteral(red: 0.5019607843, green: 0.5490196078, blue: 0.6117647059, alpha: 1)])
            case Transaction.TransactionStatus.failed: return NSAttributedString(string: "Failed", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: #colorLiteral(red: 0.5019607843, green: 0.5490196078, blue: 0.6117647059, alpha: 1)])
            }
        }
            .bind(to: self.statusLabel.rx.attributedText)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupCancelButton() {
        self.transaction.compactMap { $0?.type }
            .map { type in
                if type == .giveDonation {
                    return "Cancel (in 24 hours)"
                } else {
                    return "Cancel"
                }
            }
            .bind(to: self.cancelButton.rx.title())
            .disposed(by: self.disposeBag)
        
        self.transaction.compactMap { $0?.status }
            .map { $0 != Transaction.TransactionStatus.processing }
            .bind(to: self.cancelButton.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTypeImage() {
        self.transaction.compactMap { $0?.type }
            .map { type in
                switch type {
                case Transaction.TransactionType.giveDonation: return #imageLiteral(resourceName: "give")
                case Transaction.TransactionType.transferToGAT, Transaction.TransactionType.transferToApp: return #imageLiteral(resourceName: "transfer")
                case Transaction.TransactionType.send: return #imageLiteral(resourceName: "iconoir_log-out")
                case Transaction.TransactionType.receive: return #imageLiteral(resourceName: "iconoir_log-in")
                default: return #imageLiteral(resourceName: "iconoir_bookmark-book")
                }
            }
            .bind(to: self.typeImageView.rx.image)
            .disposed(by: self.disposeBag)
        self.transaction.compactMap { $0?.type }
            .map { type in
                
                switch type {
                case Transaction.TransactionType.giveDonation: return #colorLiteral(red: 0.9921568627, green: 0.9176470588, blue: 0.8784313725, alpha: 1)
                case Transaction.TransactionType.transferToGAT: return #colorLiteral(red: 0.9568627451, green: 0.9490196078, blue: 0.9803921569, alpha: 1)
                case Transaction.TransactionType.send: return #colorLiteral(red: 1, green: 0.9607843137, blue: 0.8078431373, alpha: 1)
                case Transaction.TransactionType.receive: return #colorLiteral(red: 0.8941176471, green: 0.9882352941, blue: 0.8823529412, alpha: 1)
                case Transaction.TransactionType.transferToApp: return #colorLiteral(red: 0.8941176471, green: 0.9490196078, blue: 0.9803921569, alpha: 1)
                default: return #colorLiteral(red: 0.8941176471, green: 0.9882352941, blue: 0.8823529412, alpha: 1)
                }
            }
            .bind(to: self.typeView.rx.backgroundColor)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showAddress(_ address: String) -> String {
        let count = address.count
        if address.count <= 8 {
            return address
        } else {
            let start = (address as NSString).substring(with: .init(location: 0, length: 4))
            let end = (address as NSString).substring(with: .init(location: count - 5, length: 4))
            return "\(start)...\(end)"
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.cancelButton.rx.tap
            .bind { [weak self] _ in
                guard let transaction = self?.transaction.value else { return }
                self?.cancelHandler?(transaction)
            }
            .disposed(by: self.disposeBag)
    }
}

extension TransactionCollectionViewCell {
    class func size(transaction: Transaction, in bounds: CGSize) -> CGSize {
        if transaction.status == .processing {
            return .init(width: bounds.width, height: 120)
        }
        return .init(width: bounds.width, height: 80)
    }
}
