//
//  InAppWalletViewController.swift
//  gat
//
//  Created by jujien on 01/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class InAppWalletViewController: UIViewController {
    
    class var segueIdentifier: String { "showInAppWallet" }
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let transactions = BehaviorRelay<[Transaction]>(value: [])
    fileprivate var typesSelected: [Transaction.TransactionType] =  [
        .giveDonation,
        .receiveDonation,
        .transferToGAT,
        .borrowBookFee,
        .refundBookBorrowFee,
        .refundDepositFee,
        .extensionFee,
        .refundExtensionFee,
        .overdueFee
    ]
    fileprivate var statusSelected = Transaction.TransactionStatus.allCases
    fileprivate var sorted = Transaction.Order.last90Days

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        self.balanceLabel.text = "\(formatter.string(from: .init(value: WalletService.shared.getBalanceInApp())) ?? "0") GAT"
        
        self.sortAndFilter()
    }
    
    // MARK: - Data
    fileprivate func filter(_ types: [Transaction.TransactionType], _ statuses: [Transaction.TransactionStatus]) {
        self.typesSelected = types
        self.statusSelected = statuses
        self.sortAndFilter()
    }
    
    fileprivate func sort(_ sort: Transaction.Order) {
        self.sorted = sort
        self.sortAndFilter()
    }
    
    fileprivate func sortAndFilter() {
        self.transactions.accept(WalletService.shared.transactionHistoriesInApp(types: self.typesSelected, status: self.statusSelected, order: self.sorted))
    }
    
    fileprivate func cancelTransactionHandler(_ transaction: Transaction) {
        WalletService.shared.cancel(transaction: transaction)
//        var array = self.transactions.value
//        if let index = array.index(where: {$0.id == transaction.id}) {
//            var element = array[index]
//            element.status = .canceled
//            array[index] = element
//        }
        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        self.balanceLabel.text = "\(formatter.string(from: .init(value: WalletService.shared.getBalanceInApp())) ?? "0") GAT"
        
        self.transactions.accept(WalletService.shared.transactionHistoriesInApp(types: self.typesSelected, status: self.statusSelected, order: self.sorted))
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupButton()
        self.setupCollectionView()
    }
    
    fileprivate func setupButton() {
        let imageInsets = UIEdgeInsets.init(top: 8.0, left: 0.144 * UIScreen.main.bounds.width, bottom: 8.0, right: 0.25 * UIScreen.main.bounds.width)
        let titleInsets = UIEdgeInsets.init(top: .zero, left: 4, bottom: .zero, right: .zero)
        
        self.sortButton.imageView?.contentMode = .scaleAspectFit
        self.sortButton.imageEdgeInsets = imageInsets
        self.sortButton.titleEdgeInsets = titleInsets
        
        self.filterButton.imageView?.contentMode = .scaleAspectFit
        self.filterButton.imageEdgeInsets = imageInsets
        self.filterButton.titleEdgeInsets = titleInsets
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.backgroundColor = .white
        self.collectionView.delegate = self
        self.collectionView.register(UINib(nibName: TransactionCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: TransactionCollectionViewCell.identifier)
        self.transactions.bind(to: self.collectionView.rx.items(cellIdentifier: TransactionCollectionViewCell.identifier, cellType: TransactionCollectionViewCell.self)) { index, item, cell in
            cell.transaction.accept(item)
            cell.cancelHandler = self.cancelTransactionHandler(_:)
        }
        .disposed(by: self.disposeBag)
    }
        
    //MARK: - Event
    fileprivate func event() {
        self.filterEvent()
        self.sortEvent()
    }
    
    fileprivate func filterEvent() {
        self.filterButton.rx.tap.bind { _ in
            let storyboard = UIStoryboard(name: "TransactionOption", bundle: nil)
            let filterVC = storyboard.instantiateViewController(withIdentifier: TransactionFilterViewController.className) as! TransactionFilterViewController
            filterVC.filterOption(types: [
                .giveDonation,
                .receiveDonation,
                .transferToGAT,
                .borrowBookFee,
                .refundBookBorrowFee,
                .refundDepositFee,
                .extensionFee,
                .refundExtensionFee,
                .overdueFee
            ])
            filterVC.selected(types: self.typesSelected, statuses: self.statusSelected)
            filterVC.applyHandler = self.filter(_:_:)
            let vc = SheetViewController(controller: filterVC, sizes: [.fixed(self.view.frame.height)])
            vc.topCornersRadius = 20
            self.present(vc, animated: true)
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func sortEvent() {
        self.sortButton.rx.tap.bind { _ in
            let storyboard = UIStoryboard(name: "TransactionOption", bundle: nil)
            let sortVC = storyboard.instantiateViewController(withIdentifier: SortTransactionViewController.className) as! SortTransactionViewController
            sortVC.currentSort(self.sorted)
            sortVC.selectionSort = self.sort(_:)
            let vc = SheetViewController(controller: sortVC, sizes: [.fixed(0.4 * UIScreen.main.bounds.height)])
            vc.topCornersRadius = 20
            self.present(vc, animated: true)
        }
        .disposed(by: self.disposeBag)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension InAppWalletViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return TransactionCollectionViewCell.size(transaction: self.transactions.value[indexPath.row], in: collectionView.frame.size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}
