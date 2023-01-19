//
//  TransactionFilterViewController.swift
//  gat
//
//  Created by jujien on 05/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxDataSources
import BEMCheckBox

class TransactionFilterViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var checkAllContainerView: UIView!
    @IBOutlet weak var applyButton: UIButton!
    
    var applyHandler: (([Transaction.TransactionType], [Transaction.TransactionStatus]) -> Void)?
    fileprivate let selected = BehaviorRelay<[Any]>(value: [])
    fileprivate let disposeBag = DisposeBag()
    fileprivate let items = BehaviorRelay<[SectionModel<String, Any>]>(value: [
        .init(model: "Transaction Type", items: Transaction.TransactionType.allCases),
        .init(model: "Transaction Status", items: Transaction.TransactionStatus.allCases)
    ])

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    func filterOption(types: [Transaction.TransactionType]) {
        self.items.accept([
            .init(model: "Transaction Type", items: types),
            .init(model: "Transaction Status", items: Transaction.TransactionStatus.allCases)
        ])
    }
    
    func selected(types: [Transaction.TransactionType], statuses: [Transaction.TransactionStatus]) {
        var array: [Any] = []
        array.append(contentsOf: types)
        array.append(contentsOf: statuses)
        self.selected.accept(array)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.backButton.setTitle("", for: .normal)
        self.setupCheckAll()
        self.setupCollectionView()
    }
    
    fileprivate func setupCheckAll() {
        self.view.layoutIfNeeded()
        let checkBox = BEMCheckBox(frame: self.checkAllContainerView.bounds)
        checkBox.boxType = .square
        checkBox.onFillColor = #colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1)
        checkBox.onCheckColor = .white
        checkBox.onTintColor = #colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1)
        checkBox.offFillColor = .clear
        checkBox.tintColor = #colorLiteral(red: 0.7019607843, green: 0.7294117647, blue: 0.768627451, alpha: 1)
        checkBox.on = true
        checkBox.delegate = self
        self.checkAllContainerView.addSubview(checkBox)
        Observable<Bool>.combineLatest(self.selected.asObservable(), self.items.asObservable()) { selected, items in
            let count = items.reduce(0) { result, section in
                return result + section.items.count
            }
            return selected.count == count
        }
        .bind { value in
            checkBox.on = value
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.backgroundColor = .white
        self.collectionView.register(.init(nibName: TitleHeaderCollectionReusableView.className, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TitleHeaderCollectionReusableView.identifier)
        self.collectionView.register(.init(nibName: CheckboxCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: CheckboxCollectionViewCell.identifier)
        let datasource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, Any>> { datasource, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckboxCollectionViewCell.identifier, for: indexPath) as! CheckboxCollectionViewCell
            
            if let type = item as? Transaction.TransactionType {
                cell.setupCheckBox(on: self.selected.value.compactMap { $0 as? Transaction.TransactionType }.contains(where: { $0 == type }))
                switch type {
                case .overdueFee: cell.titleLabel.text = "Overdue Fee"
                case .giveDonation: cell.titleLabel.text = "Give donation"
                case .receiveDonation: cell.titleLabel.text = "Receive Donation"
                case .transferToGAT: cell.titleLabel.text = "Transfer to GAT wallet"
                case .borrowBookFee: cell.titleLabel.text = "Borrow book fee"
                case .refundBookBorrowFee: cell.titleLabel.text = "Refund book borrow fee"
                case .refundDepositFee: cell.titleLabel.text = "Refund deposit fee"
                case .extensionFee: cell.titleLabel.text = "Extension fee"
                case .refundExtensionFee: cell.titleLabel.text = "Refund extension fee"
                case .send: cell.titleLabel.text = "Send"
                case .receive: cell.titleLabel.text = "Receive"
                case .transferToApp: cell.titleLabel.text = "Transfer to app"
                }
            }
            if let status = item as? Transaction.TransactionStatus {
                cell.setupCheckBox(on: self.selected.value.compactMap { $0 as? Transaction.TransactionStatus }.contains(where: { $0 == status }))
                switch status {
                case .canceled: cell.titleLabel.text = "Canceled"
                case .failed: cell.titleLabel.text = "Failed"
                case .success: cell.titleLabel.text = "Success"
                case .processing: cell.titleLabel.text = "Processing"
                }
            }
            
            return cell
        } configureSupplementaryView: { datasource, collectionView, kind, indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TitleHeaderCollectionReusableView.identifier, for: indexPath) as! TitleHeaderCollectionReusableView
            header.titleLabel.text = datasource[indexPath.section].identity
            return header
        }
        self.items.bind(to: self.collectionView.rx.items(dataSource: datasource)).disposed(by: self.disposeBag)

    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.collectionViewEvent()
        self.applyEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.bind { _ in
            self.dismiss(animated: true)
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx
            .modelSelected(Any.self)
            .bind { value in
                var array = self.selected.value
                if let type = value as? Transaction.TransactionType {
                    if let index = array.firstIndex(where: { ($0 as? Transaction.TransactionType) != nil && ($0 as! Transaction.TransactionType) == type }) {
                        array.remove(at: index)
                    } else {
                        array.append(type)
                    }
                }
                if let status = value as? Transaction.TransactionStatus {
                    if let index = array.firstIndex(where: { ($0 as? Transaction.TransactionStatus) != nil && ($0 as! Transaction.TransactionStatus) == status }) {
                        array.remove(at: index)
                    } else {
                        array.append(status)
                    }
                }
                self.selected.accept(array)
                self.collectionView.reloadData()
                
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func applyEvent() {
        self.applyButton.rx.tap.bind { _ in
            let types = self.selected.value.compactMap { $0 as? Transaction.TransactionType }
            let status = self.selected.value.compactMap { $0 as? Transaction.TransactionStatus }
            self.applyHandler?(types, status)
            self.dismiss(animated: true)
        }
        .disposed(by: self.disposeBag)
    }

}

extension TransactionFilterViewController: BEMCheckBoxDelegate {
    func didTap(_ checkBox: BEMCheckBox) {
        if checkBox.on {
            var array: [Any] = Transaction.TransactionType.allCases
            array.append(contentsOf: Transaction.TransactionStatus.allCases)
            self.selected.accept(array)
        } else {
            self.selected.accept([])
        }
        self.collectionView.reloadData()
    }
}

extension TransactionFilterViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: collectionView.frame.width, height: 32.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width, height: 32.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: .zero, left: .zero, bottom: 16.0, right: .zero)
    }
}
