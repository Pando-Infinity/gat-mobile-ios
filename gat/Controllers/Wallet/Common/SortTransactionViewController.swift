//
//  SortTransactionViewController.swift
//  gat
//
//  Created by jujien on 06/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxDataSources

class SortTransactionViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let items = BehaviorRelay<[SectionModel<String, Transaction.Order>]>(value: [
        .init(model: "Time", items: Transaction.Order.allCases)
    ])
    
    fileprivate let sortItem = BehaviorRelay(value: Transaction.Order.last90Days)
    
    var selectionSort: ((Transaction.Order) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    func currentSort(_ sort: Transaction.Order) {
        self.sortItem.accept(sort)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.cancelButton.setTitle("", for: .normal)
        self.setupCollectionView()
        self.sortItem.bind { _ in
            self.collectionView.reloadData()
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self 
        self.collectionView.backgroundColor = .white
        
        self.collectionView.register(.init(nibName: TitleHeaderCollectionReusableView.className, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TitleHeaderCollectionReusableView.identifier)
        self.collectionView.register(.init(nibName: CheckboxCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: CheckboxCollectionViewCell.identifier)
        
        let datasource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, Transaction.Order>> { datasource, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckboxCollectionViewCell.identifier, for: indexPath) as! CheckboxCollectionViewCell
            cell.setupRadio(on: item == self.sortItem.value)
            switch item {
            case .today: cell.titleLabel.text = "Today"
            case .last7Days: cell.titleLabel.text = "Last 7 days"
            case .last30Days: cell.titleLabel.text = "Last 30 days"
            case .last90Days: cell.titleLabel.text = "Last 90 days"
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
        self.applyEvent()
        self.collectionViewEvent()
    }
    
    fileprivate func backEvent() {
        self.cancelButton.rx.tap.bind { _ in
            self.dismiss(animated: true)
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func applyEvent() {
        self.applyButton.rx.tap.bind { _ in
            self.selectionSort?(self.sortItem.value)
            self.dismiss(animated: true)
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(Transaction.Order.self)
            .bind { order in
                self.sortItem.accept(order)
            }
            .disposed(by: self.disposeBag)
    }

}

extension SortTransactionViewController: UICollectionViewDelegateFlowLayout {
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
