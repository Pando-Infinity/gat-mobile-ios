//
//  ListOptionFilterViewController.swift
//  gat
//
//  Created by jujien on 2/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class ListOptionFilterViewController: UIViewController {
    
    class var identifier: String { return ListOptionFilterViewController.className }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterButton: UIButton!
    
    let name: BehaviorSubject<String> = .init(value: Gat.Text.Filterable.FILTER_BUTTON.localized())
    let items: BehaviorSubject<[(Filterable, [Filterable])]> = .init(value: [])
    let selected: BehaviorSubject<[(Filterable, [Filterable])]> = .init(value: [])
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
        self.filterButton.setTitle(Gat.Text.Filterable.ACCEPT_FILTER_BUTTON.localized(), for: .normal)
        self.tableView.tableFooterView = UIView()
        self.items
            .bind(to: self.tableView.rx.items(cellIdentifier: ItemOptionFilterTableViewCell.identifier, cellType: ItemOptionFilterTableViewCell.self)) { [weak self] (index, item, cell) in
                cell.titleLabel.text = item.0.name
                if let value = try? self?.selected.value(), let select = value {
                    if select.first(where: { $0.0.value == item.0.value })?.1.count == item.1.count {
                        cell.selectTitleLabel.text = Gat.Text.Filterable.ALL_FILTERABLE.localized()
                    } else {
                        let selectItem = select.first(where: {$0.0.value == item.0.value})?.1.map { $0.name } ?? []
                        cell.selectTitleLabel.text = selectItem.joined(separator: ",")
                    }
                }
            }
            .disposed(by: self.disposeBag)
        self.selected.subscribe(onNext: { [weak self] (selected) in
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func update(select: Observable<[Filterable]>, in item: Filterable) {
        select.withLatestFrom(self.selected, resultSelector: { ($0, $1) })
            .map { (selectItems, list) -> [(Filterable, [Filterable])] in
                var items = list
                if list.isEmpty {
                    items = [(item, selectItems)]
                } else if let index = list.firstIndex(where: {$0.0.value == item.value }) {
                    items[index] = (item, selectItems)
                } else {
                    items.append((item, selectItems))
                }
                return items
            }
            .subscribe(onNext: self.selected.onNext)
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.tableView.rx
            .modelSelected((Filterable, [Filterable]).self)
            .subscribe(onNext: { [weak self] (item) in
                self?.performSegue(withIdentifier: FilterListViewController.segueIdentifier, sender: item)
            })
            .disposed(by: self.disposeBag)
        self.filterButton.rx.tap.asObservable().withLatestFrom(self.selected)
            .filter { !$0.isEmpty && $0.reduce(true, { $0 && !$1.1.isEmpty }) }
            .subscribe(onNext: { [weak self] (_) in
                self?.navigationController?.dismiss(animated: true, completion: nil)
                self?.accept.onNext(true)
            }).disposed(by: self.disposeBag)
    }
    
    func acceptSelect() -> Observable<[(Filterable, [Filterable])]> {
        return self.accept.filter{ $0 }.withLatestFrom(self.selected)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == FilterListViewController.segueIdentifier {
            let vc = segue.destination as! FilterListViewController
            let item = sender as! (Filterable, [Filterable])
            vc.name.onNext(item.0.name)
            vc.showBack.onNext(true)
            vc.items.onNext(item.1)
            if let value = try? self.selected.value(), let itemSelected = value.first(where: { $0.0.value == item.0.value })?.1 {
                vc.selected.onNext(itemSelected)
            }
            self.update(select: vc.acceptSelect(), in: item.0)
        }
    }

}
