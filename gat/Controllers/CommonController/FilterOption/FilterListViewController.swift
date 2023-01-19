//
//  FilterListViewController.swift
//  gat
//
//  Created by jujien on 2/13/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol Filterable {
    var name: String { get }
    
    var value: Int { get }
}

class FilterListViewController: UIViewController {
    
    class var segueIdentifier: String { return "showListFilter" }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectAllButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    let items: BehaviorSubject<[Filterable]> = .init(value: [])
    let selected: BehaviorSubject<[Filterable]> = .init(value: [])
    let name: BehaviorSubject<String> = .init(value: Gat.Text.Filterable.FILTER_BUTTON.localized())
    let showBack: BehaviorSubject<Bool> = .init(value: false)
    fileprivate let accept: BehaviorSubject<Bool> = .init(value: false)
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.name.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.acceptButton.setTitle(Gat.Text.Filterable.ACCEPT_FILTER_BUTTON.localized(), for: .normal)
        self.showBack.map{ !$0 }.bind(to: self.backButton.rx.isHidden).disposed(by: self.disposeBag)
        self.setupTableView()
        self.setupSelectAll()
    }
    
    fileprivate func setupTableView() {
        self.tableView.tableFooterView = UIView()
        self.items
            .bind(to: self.tableView.rx.items(cellIdentifier: FilterListTableViewCell.identifier, cellType: FilterListTableViewCell.self)) { [weak self] (index, item, cell) in
                cell.titleLabel.text = item.name
                cell.item = item
                cell.delegate = self
                if let value = try? self?.selected.value(), let select = value {
                    cell.selectButton.setImage(select.contains(where: { $0.value == item.value }) ? #imageLiteral(resourceName: "checked") : nil, for: .normal)
                }
            }
            .disposed(by: self.disposeBag)
        
        self.selected.map { _ in }.subscribe(onNext: self.tableView.reloadData).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSelectAll() {
        Observable.combineLatest(self.items, self.selected, resultSelector: { ($0, $1) })
            .map { $0.count == $1.count }
            .subscribe(onNext: self.selectAll(_:))
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func selectAll(_ value: Bool) {
        self.selectAllButton.setImage(value ? #imageLiteral(resourceName: "checked") : nil, for: .normal)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.selectAllEvent()
        self.acceptButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.accept.onNext(true)
            if self?.navigationController == nil {
                self?.dismiss(animated: true, completion: nil)
            } else {
                self?.navigationController?.popViewController(animated: true)
            }
        })
            .disposed(by: self.disposeBag)
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func selectAllEvent() {
        self.selectAllButton.rx.tap.asObservable()
            .withLatestFrom(self.selected)
            .withLatestFrom(self.items, resultSelector: { ($0, $1) })
            .map { (select, item) -> [Filterable] in
                if select.count == item.count { return [] }
                return item
            }
            .do(onNext: { [weak self] (select) in
                self?.selectAllButton.setImage(select.isEmpty ? nil : UIImage(named: "checked"), for: .normal)
            })
            .subscribe(self.selected)
            .disposed(by: self.disposeBag)
    }
    
    func acceptSelect() -> Observable<[Filterable]> {
        return self.accept.filter { $0 }.withLatestFrom(self.selected)
    }

}

extension FilterListViewController: FilterListDelegate {
    func selectFilter(item: Filterable) {
        guard var value = try? self.selected.value() else { return }
        if value.contains(where: { $0.value == item.value }) {
            value.removeAll(where: {$0.value == item.value })
        } else {
            value.append(item)
        }
        self.selected.onNext(value)
    }
}
