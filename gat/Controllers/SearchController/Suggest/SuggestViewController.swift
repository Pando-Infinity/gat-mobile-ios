//
//  SuggestViewController.swift
//  gat
//
//  Created by Vũ Kiên on 10/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class SuggestViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupUI()
        self.event()
    }
    
    fileprivate func setupUI() {
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
    }
    
    // MARK: - Event
    fileprivate func event() {
        LanguageHelper.changeEvent.subscribe(onNext: self.tableView.reloadData).disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        } else if segue.identifier == Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER {
            let vc = segue.destination as? BookStopViewController
            vc?.bookstop.onNext(sender as! Bookstop)
        } else if segue.identifier == "showBookstopOrganization" {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        }
    }

}

extension SuggestViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nearbyUserCell", for: indexPath) as! NearByUserTableViewCell
            cell.controller = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "bookSuggestion", for: indexPath) as! BookSuggestionTableViewCell
            cell.controller = self
            return cell
        }
        
    }
}

extension SuggestViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = Bundle.main.loadNibNamed(Gat.View.HEADER, owner: self, options: nil)?.first as? HeaderSearch
        if section == 0 {
            header?.titleLabel.text = Gat.Text.Home.NEARBY_USER_TITLE.localized()
            header?.showView.isHidden = false
            header?.titleButton.text = Gat.Text.Home.MORE_TITLE.localized()
            header?.showView
                .rx
                .tapGesture()
                .when(.recognized)
                .bind(onNext: { [weak self] (_) in
                self?.performSegue(withIdentifier: Gat.Segue.NEARBY_USER_IDENTIFIER, sender: nil)
            })
                .disposed(by: self.disposeBag)
            header?.titleButton.textColor = .white
        } else {
            header?.titleLabel.text = Gat.Text.Home.BOOK_SHARING_TITLE.localized()
            header?.showView.isHidden = true
        }
        header?.titleLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return self.tableView.frame.height * 0.16
        } else {
            return 0.74 * self.tableView.frame.height
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.05 * self.tableView.frame.height
    }
}






