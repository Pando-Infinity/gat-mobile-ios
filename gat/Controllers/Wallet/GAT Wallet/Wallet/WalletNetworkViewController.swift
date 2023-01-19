//
//  WalletNetworkViewController.swift
//  gat
//
//  Created by jujien on 07/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class WalletNetworkViewController: UIViewController {
    
    class var segueIdentifier: String { "showWalletNetwork" }
    
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sendView: UIView!
    @IBOutlet weak var receiveView: UIView!
    @IBOutlet weak var transferView: UIView!
    @IBOutlet weak var receiveLabel: UILabel!
    @IBOutlet weak var sendLabel: UILabel!
    @IBOutlet weak var transferLabel: UILabel!
    @IBOutlet weak var receiveLowCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var receiveHighCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendHighCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendLowCenterXConstraint: NSLayoutConstraint!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let transactions = BehaviorRelay<[Transaction]>(value: Transaction.data1.sorted(by: { $0.date > $1.date}))
    fileprivate var typesSelected: [Transaction.TransactionType] = []
    fileprivate var statusSelected = Transaction.TransactionStatus.allCases
    fileprivate var sorted = Transaction.Order.last90Days
    
    let network = BehaviorRelay<NetworkCurrency>(value: .gat)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        self.network.map { network in
            if network == .gat {
                return [Transaction.TransactionType.send, Transaction.TransactionType.receive, Transaction.TransactionType.transferToApp]
            } else {
                return [Transaction.TransactionType.send, Transaction.TransactionType.receive]
            }
        }
        .bind { value in
            self.typesSelected = value
            self.sortAndFilter()
        }
        .disposed(by: self.disposeBag)
    }
    
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
        let items = Transaction.data1
        let results = items.filter { transaction in
            return self.statusSelected.contains(where: { $0 == transaction.status })
            && self.typesSelected.contains(where: { $0 == transaction.type })
        }
            .filter { transaction in
                switch self.sorted {
                case .today: return Calendar.current.isDateInToday(transaction.date)
                case .last7Days: return transaction.date > Date().addingTimeInterval(-604800)
                case .last30Days: return transaction.date > Date().addingTimeInterval(-2_592_000)
                case .last90Days: return transaction.date > Date().addingTimeInterval(-7_776_000)
                }
            }
        self.transactions.accept(results)
    }
    
    fileprivate func cancelTransactionHandler(_ transaction: Transaction) {
        var array = self.transactions.value
        if let index = array.index(where: {$0.id == transaction.id}) {
            var element = array[index]
            element.status = .canceled
            array[index] = element
        }
        self.transactions.accept(array)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        
        self.network.map { network in
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            let value = formatter.string(from: .init(value: WalletService.shared.balance(network: network))) ?? "0"
            switch network {
            case NetworkCurrency.gat: return value + " GAT"
            case NetworkCurrency.sol: return value + "SOL"
            }
        }
        .bind(to: self.balanceLabel.rx.text)
        .disposed(by: self.disposeBag)
        
        self.setupNavigation()
        self.backButton.setTitle("", for: .normal)
        self.setupSortAndFilterButton()
        self.setupSendButton()
        self.setupReceiveButton()
        self.setupCollectionView()
        self.network.map { $0 != .gat }
            .bind(to: self.transferView.rx.isHidden, self.transferLabel.rx.isHidden)
            .disposed(by: self.disposeBag)
        self.network.map { network in
            switch network {
            case .gat: return "GAT"
            case .sol: return "SOL"
            }
        }.bind(to: self.titleLabel.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSortAndFilterButton() {
        let imageInsets = UIEdgeInsets.init(top: 8.0, left: 0.144 * UIScreen.main.bounds.width, bottom: 8.0, right: 0.25 * UIScreen.main.bounds.width)
        let titleInsets = UIEdgeInsets.init(top: .zero, left: 4, bottom: .zero, right: .zero)
        
        self.sortButton.imageView?.contentMode = .scaleAspectFit
        self.sortButton.imageEdgeInsets = imageInsets
        self.sortButton.titleEdgeInsets = titleInsets
        
        self.filterButton.imageView?.contentMode = .scaleAspectFit
        self.filterButton.imageEdgeInsets = imageInsets
        self.filterButton.titleEdgeInsets = titleInsets
    }
    
    fileprivate func setupSendButton() {
        self.network.bind { network in
            if network == .gat {
                self.sendHighCenterXConstraint.priority = .defaultHigh
                self.sendLowCenterXConstraint.priority = .defaultLow
            } else {
                self.sendHighCenterXConstraint.priority = .defaultLow
                self.sendLowCenterXConstraint.priority = .defaultHigh
            }
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupReceiveButton() {
        self.network.bind { network in
            if network == .gat {
                self.receiveHighCenterXConstraint.priority = .defaultHigh
                self.receiveLowCenterXConstraint.priority = .defaultLow
            } else {
                self.receiveHighCenterXConstraint.priority = .defaultLow
                self.receiveLowCenterXConstraint.priority = .defaultHigh
            }
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupNavigation() {
        self.view.layoutIfNeeded()
        self.navigationView.applyGradient(colors: [#colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1), #colorLiteral(red: 0.5725490196, green: 0.5921568627, blue: 0.9098039216, alpha: 1)], start: .zero, end: .init(x: 1.0, y: .zero))
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
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.filterEvent()
        self.sortEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.bind { _ in
            self.navigationController?.popViewController(animated: true)
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func filterEvent() {
        self.filterButton.rx.tap.bind { _ in
            let storyboard = UIStoryboard(name: "TransactionOption", bundle: nil)
            let filterVC = storyboard.instantiateViewController(withIdentifier: TransactionFilterViewController.className) as! TransactionFilterViewController
            if self.network.value == .gat {
                filterVC.filterOption(types: [.send, .receive, .transferToApp])
            } else {
                filterVC.filterOption(types: [.send, .receive])
            }
            
            filterVC.selected(types: self.typesSelected, statuses: self.statusSelected)
            filterVC.applyHandler = self.filter(_:_:)
            let sizes: [SheetSize]
            if self.network.value == .gat {
                sizes = [.fixed(480)]
            } else {
                sizes = [.fixed(450)]
            }
            let vc = SheetViewController(controller: filterVC, sizes: sizes)
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

}

extension WalletNetworkViewController: UICollectionViewDelegateFlowLayout {
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
