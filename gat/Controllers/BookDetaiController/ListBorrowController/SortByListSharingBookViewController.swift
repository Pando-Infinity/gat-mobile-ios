//
//  SortByListSharingBookViewController.swift
//  gat
//
//  Created by Vũ Kiên on 09/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SortByListSharingBookViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var option: SortOption!
    fileprivate let disposeBag = DisposeBag()
    fileprivate let options = Variable<[SortOption]>([.activeTime, .distance])
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.titleLabel.text = Gat.Text.SortByListSharingBook.SORT_BY_TITLE.localized()
        self.setup()
        self.event()
    }
    
    fileprivate func setup() {
        self.options.asDriver().drive(self.tableView.rx.items(cellIdentifier: "sortByCell", cellType: SortByTableViewCell.self)) { [weak self] (index, title, cell) in
            if let option = self?.option {
                cell.setup(title: title.toString(), active: option == title)
            }
        }.disposed(by: self.disposeBag)
        self.tableView.tableFooterView = UIView()
    }
    
    fileprivate func event() {
        self.selectedEvent()
        self.backEvent()
    }
    
    fileprivate func selectedEvent() {
        self.tableView.rx.modelSelected(SortOption.self).asDriver().drive(onNext: { [weak self] (option) in
            self?.option = option
            self?.tableView.reloadData()
            self?.performSegue(withIdentifier: "backListSharing", sender: nil)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }

}
