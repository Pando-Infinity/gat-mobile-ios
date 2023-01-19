//
//  BookSuggestViewController.swift
//  gat
//
//  Created by Vũ Kiên on 24/08/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import XLPagerTabStrip

class BookSuggestViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    fileprivate let disposeBag = DisposeBag()
    fileprivate let items = BehaviorSubject<[SectionModel<String, SuggestBookByModeRequest.SuggestBookMode>]>(value: [])
    fileprivate var dataSource: RxTableViewSectionedReloadDataSource<SectionModel<String, SuggestBookByModeRequest.SuggestBookMode>>!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        Observable<[SuggestBookByModeRequest.SuggestBookMode]>
            .just([.topBorrowing, .topRating, .near, .history])
            .map { (modes) -> [SectionModel<String, SuggestBookByModeRequest.SuggestBookMode>] in
                return modes.map({ (mode) -> SectionModel<String, SuggestBookByModeRequest.SuggestBookMode> in
                    return SectionModel<String, SuggestBookByModeRequest.SuggestBookMode>(model: mode.title, items: [mode])
                })
            }
            .subscribe(onNext: self.items.onNext)
            .disposed(by: self.disposeBag)
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, SuggestBookByModeRequest.SuggestBookMode>>.init(configureCell: { [weak self] (datasource, tableView, indexPath, element) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: BookSuggestModeTableViewCell.identifier, for: indexPath) as! BookSuggestModeTableViewCell
            cell.mode.onNext(element)
            cell.delegate = self
            return cell
        })
        self.items.bind(to: self.tableView.rx.items(dataSource: self.dataSource)).disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        LanguageHelper.changeEvent.subscribe(onNext: self.tableView.reloadData).disposed(by: self.disposeBag)
    }
    
    fileprivate func showMoreEvent(header: HeaderSearch, mode: SuggestBookByModeRequest.SuggestBookMode) {
        header.showView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.performSegue(withIdentifier: "showExploreBook", sender: mode)
        }).disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBookDetail" {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == "showExploreBook" {
            let vc = segue.destination as? ExploreBookViewController
            vc?.mode.onNext(sender as? SuggestBookByModeRequest.SuggestBookMode)
            vc?.titleText.onNext((sender as! SuggestBookByModeRequest.SuggestBookMode).title)
        }
    }
}

extension BookSuggestViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 225.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let items = try? self.items.value() else { return nil }
        let header = Bundle.main.loadNibNamed("HeaderSearch", owner: self, options: nil)?.first as? HeaderSearch
        header?.titleLabel.text = items[section].model
        header?.titleLabel.textColor = .black
        header?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
        header?.titleButton.text = Gat.Text.Home.MORE_TITLE.localized()
        header?.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
        header?.showView.isHidden = false
        header?.backgroundColor = .white
        header?.showView.isUserInteractionEnabled = true
        if let header = header, let mode = items[section].items.first {
            self.showMoreEvent(header: header, mode: mode)
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
}

extension BookSuggestViewController: HomeDelegate {
    func showView(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension BookSuggestViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return .init(title: Gat.Text.BookSuggest.TITLE.localized().uppercased())
    }
    
    
}
