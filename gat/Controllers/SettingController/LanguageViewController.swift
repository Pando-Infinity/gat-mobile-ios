//
//  LanguageViewController.swift
//  gat
//
//  Created by jujien on 2/13/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class LanguageViewController: UIViewController {
    
    class var segueIdentifier: String { return "showLanguage" }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var select: LanguageSupport?
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let text = UserDefaults.standard.string(forKey: "language"), let current = LanguageSupport(rawValue: text) {
            self.select = current
        }
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = Gat.Text.Language.TITLE.localized()
        Observable.just(LanguageSupport.allCases)
            .bind(to: self.tableView.rx.items(cellIdentifier: UITableViewCell.identifier)) { [weak self] (index, language, cell) in
                cell.textLabel?.text = language.name
                if let current = self?.select, current == language {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
            .disposed(by: self.disposeBag)
        self.tableView.tableFooterView = UIView()
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backButtonEvent()
        self.tableViewEvent()
        self.saveEvent()
    }
    
    fileprivate func backButtonEvent() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func tableViewEvent() {
        self.tableView.rx.modelSelected(LanguageSupport.self).map { (language) -> UIImage in
            if let text = UserDefaults.standard.string(forKey: "language"), let current = LanguageSupport(rawValue: text), current != language {
                return #imageLiteral(resourceName: "check_green-icon")
            } else {
                return #imageLiteral(resourceName: "IconCheck_Disabled")
            }
            }.subscribe(onNext: { [weak self] (image) in
                self?.saveButton.setImage(image, for: .normal)
            }).disposed(by: self.disposeBag)
        self.tableView.rx.modelSelected(LanguageSupport.self).map { (language) -> Bool in
            if let text = UserDefaults.standard.string(forKey: "language"), let current = LanguageSupport(rawValue: text), current != language {
                return true
            } else {
                return false
            }
        }.subscribe(self.saveButton.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
        
        self.tableView.rx.modelSelected(LanguageSupport.self).subscribe(onNext: { [weak self] (language) in
            self?.select = language
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func saveEvent() {
        self.saveButton.rx.tap
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                guard let select = self?.select else { return }
                UserDefaults.standard.set(select.rawValue, forKey: "language")
                self?.titleLabel.text = Gat.Text.Language.TITLE.localized()
                LanguageHelper.changeEvent.onNext(())
                self?.navigationController?.popViewController(animated: true)
                
            })
            .disposed(by: self.disposeBag)
    }

}

fileprivate extension UITableViewCell {
    fileprivate class var identifier: String { return "languageCell" }
}
