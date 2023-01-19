//
//  FilterListTableViewCell.swift
//  gat
//
//  Created by jujien on 2/13/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol FilterListDelegate: class {
    func selectFilter(item: Filterable)
}

class FilterListTableViewCell: UITableViewCell {
    
    class var identifier: String { return "filterCell" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    
    weak var delegate: FilterListDelegate?
    var item: Filterable!
    
    fileprivate let disposeBag: DisposeBag = .init()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectButton.rx.tap.asObservable().withLatestFrom(Observable.just(self.selectButton)).subscribe(onNext: self.check(button:)).disposed(by: self.disposeBag)
    }
    
    fileprivate func check(button: UIButton) {
        self.delegate?.selectFilter(item: self.item)
    }
}
