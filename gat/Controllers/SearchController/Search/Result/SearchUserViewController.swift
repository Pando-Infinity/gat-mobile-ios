//
//  SearchUserViewController.swift
//  gat
//
//  Created by Vũ Kiên on 03/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation

class SearchUserViewController: UIViewController {
    
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var suggestionTableView: UITableView!
    @IBOutlet weak var loadingView: UIImageView!

    let textSearch = BehaviorSubject<String>(value: "")
    let activeSearch = BehaviorSubject<Bool>(value: false)
    let page = BehaviorSubject<Int>(value: 1)
    var showSearch: SearchState = .new
    var status: ShowState = .history
    weak var controller: SearchViewController?
    
    fileprivate let histories = BehaviorSubject<[History]>(value: [])
    fileprivate let suggestions: BehaviorSubject<[UserPublic]> = .init(value: [])
    fileprivate let users = BehaviorSubject<[UserPublic]>(value: [])
    fileprivate var header: HeaderSearch?
    fileprivate let totalResult = BehaviorSubject<Int>(value: 0)
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupUI()
        self.getData()
        self.event()
    }

    //MARK: - Data
    fileprivate func getData() {
        self.getHistory()
        self.searchUser()
        self.getSuggestion()
    }
    
    func getHistory() {
        Observable.just(Session.shared.isAuthenticated).filter { $0 }
            .flatMapLatest { _ in Repository<History, HistoryObject>.shared.getAll(predicateFormat: "type = %@", args: [HistoryType.user.rawValue]) }
            .do(onNext: { [weak self] (histories) in
                self?.histories.onNext(histories)
            })
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.waitInteracter(true)
            })
            .flatMapLatest { _ in HistoryNetworkService.shared.searchHistory(type: .user).catchErrorJustReturn([]) }
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (histories) in
                self?.waitInteracter(false)
                self?.histories.onNext(histories)
                histories.forEach({ [weak self] (history) in
                    self?.controller?.addHistory(history)
                })
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getSuggestion() {
        self.controller?.delegate?.textSearch
            .do(onNext: { [weak self] (text) in
                if text.isEmpty {
                    self?.status = .history
                    self?.historyTableView.isHidden = false
                    self?.suggestionTableView.isHidden = true
                }
            })
            .filter { !$0.isEmpty }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.status = .suggest
            })
            .flatMap { SearchSuggestionService.shared.suggestionUser(text: $0).catchErrorJustReturn([]) }
            .subscribe(onNext: self.suggestions.onNext)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func searchUser() {
        Observable<(String, CLLocationCoordinate2D?, Int, Bool)>.combineLatest(self.textSearch.asObservable(), self.getLocation(), self.page.asObservable(), self.activeSearch.asObservable(), resultSelector: { ($0, $1, $2, $3) })
            .filter { $0.3 && !$0.0.isEmpty && Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.waitInteracter(true)
            })
            .map { ($0.0, $0.1, $0.2) }
            .flatMap { (text, location, page) -> Observable<([UserPublic], Int)> in
                return SearchNetworkService.shared.user(name: text, location: location, page: page)
                    .catchError { [weak self] (error) -> Observable<([UserPublic], Int)> in
                        self?.waitInteracter(false)
                        HandleError.default.showAlert(with: error)
                        return .empty()
                    }
            }
        .subscribe(onNext: { [weak self] (lists, total) in
            self?.waitInteracter(false)
            self?.status = .search
            self?.activeSearch.onNext(false)
            self?.totalResult.onNext(total)
            guard let value = try? self?.users.value(), var users = value, let status = self?.showSearch else {
                return
            }

            switch status {
            case .new: users = lists
            case .more: users.append(contentsOf: lists)
            }
            self?.users.onNext(users)

        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func getLocation() -> Observable<CLLocationCoordinate2D?> {
        return LocationManager.manager.location.catchErrorJustReturn(.init()).map { (location) -> CLLocationCoordinate2D? in
            if location == CLLocationCoordinate2D() { return nil }
            return location
        }
    }
    
    func startSearch(with title: String) {
        self.status = .search
        self.showSearch = .new
        self.page.onNext(1)
        self.textSearch.onNext(title)
        self.activeSearch.onNext(true)
        self.refreshHistory()
    }
    
    fileprivate func refreshHistory() {
           Repository<History, HistoryObject>.shared.getAll(predicateFormat: "type = %@", args: [HistoryType.user.rawValue]).subscribe(onNext: self.histories.onNext).disposed(by: self.disposeBag)
       }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.setupTableView()
        self.loadingUI()
    }
    
    fileprivate func setupTableView() {
        self.setupSearchTableView()
        self.setupHistoriesTableView()
        self.setupSuggestionTableView()
        self.setupTotalResultHeader()
    }
    
    fileprivate func setupSuggestionTableView() {
        self.suggestionTableView.delegate = self
        self.suggestionTableView.register(UINib.init(nibName: SuggestionUserTableViewCell.className, bundle: nil), forCellReuseIdentifier: SuggestionUserTableViewCell.identifier)
        self.suggestionTableView.tableFooterView = UIView()
        self.suggestions
            .do(onNext: { [weak self] (texts) in
                guard let status = self?.status, status == .suggest else {
                    return
                }
                self?.historyTableView.isHidden = true
                self?.searchTableView.isHidden = true
                self?.suggestionTableView.isHidden = false
            })
            .bind(to: self.suggestionTableView.rx.items(cellIdentifier: SuggestionUserTableViewCell.identifier, cellType: SuggestionUserTableViewCell.self))
            { (index, user, cell) in
                cell.layoutIfNeeded()
                cell.userImageView.circleCorner()
                cell.user.accept(user.profile)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupHistoriesTableView() {
        self.historyTableView.delegate = self
        
        let nib2 = UINib(nibName: Gat.View.HISTORY_SEARCH_TABLE_CELL, bundle: nil)
        self.historyTableView.register(nib2, forCellReuseIdentifier: Gat.Cell.IDENTIFIER_HISTORY_SEARCH)
        
        self.historyTableView.tableFooterView = UIView()
        
        self.histories
            .do(onNext: { [weak self] (_) in
                guard let status = self?.status, status == .history else {
                    self?.historyTableView.isHidden = true
                    self?.searchTableView.isHidden = false
                    self?.suggestionTableView.isHidden = true
                    return
                }
                self?.historyTableView.isHidden = false
                self?.searchTableView.isHidden = true
                self?.suggestionTableView.isHidden = true
            })
            .bind(to: self.historyTableView.rx.items(cellIdentifier: Gat.Cell.IDENTIFIER_HISTORY_SEARCH, cellType: HistoryTableViewCell.self))
            { (row, history, cell) in
                cell.setupHistory(label: history.text, index: 2)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSearchTableView() {
        self.searchTableView.delegate = self
        self.searchTableView.tableFooterView = UIView()
        self.users
            .do(onNext: { [weak self] (_) in
                guard let status = self?.status, status == .search else {
                    self?.searchTableView.isHidden = true
                    self?.historyTableView.isHidden = false
                    self?.suggestionTableView.isHidden = true
                    return
                }
                self?.searchTableView.isHidden = false
                self?.historyTableView.isHidden = true
                self?.suggestionTableView.isHidden = true
            })
            .bind(to: self.searchTableView.rx.items(cellIdentifier: Gat.Cell.IDENTIFIER_FRIEND, cellType: UserResultTableViewCell.self))
            { (index, user, cell) in
                cell.setup(userPublic: user)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTotalResultHeader() {
        self.totalResult
            .bind { [weak self] (total) in
                self?.setupHeader(count: total)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupHeader(count: Int) {
        if self.header == nil {
            self.view.layoutIfNeeded()
            self.header = Bundle.main.loadNibNamed(Gat.View.HEADER, owner: self.controller, options: nil)?.first as? HeaderSearch
            self.header?.frame.size.height = self.searchTableView.frame.height * 0.06
            self.header?.showView.isHidden = true
            self.header?.backgroundColor = .white
        }
        var countString = ""
        var range: NSRange!
        if count <= 9 && count > 0 {
            countString = "0\(count)"
        } else {
            countString = "\(count)"
        }
        let attributes = NSMutableAttributedString(string: String(format: Gat.Text.Search.RESULT_SEARCH_TITLE.localized(), countString), attributes: [NSAttributedString.Key.foregroundColor: SHOW_TITLE_TEXT_COLOR, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.regular)])
        range = (String(format: Gat.Text.Search.RESULT_SEARCH_TITLE.localized(), countString) as NSString).range(of: countString)
        attributes.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.semibold)], range: range)
        header?.titleLabel.attributedText = attributes
    }
    
    fileprivate func loadingUI() {
        let urlGif = Bundle.main.url(forResource: LOADING_GIF, withExtension: EXTENSION_GIF)
        self.loadingView.sd_setImage(with: urlGif!)
        self.loadingView.isHidden = true
    }
    
    func waitInteracter(_ isWait: Bool) {
        self.loadingView.isHidden = !isWait
    }

    //MARK: - Event
    fileprivate func event() {
        self.tableViewEvent()
        self.totalResultEvent()
        LanguageHelper.changeEvent.filter { [weak self] _ in self?.status == .search }.flatMap { [weak self] (_) -> Observable<Int> in
            guard let result = self?.totalResult else { return Observable.empty() }
            return Observable<Int>.from(optional: try? result.value())
            }.subscribe(onNext: self.totalResult.onNext).disposed(by: self.disposeBag)
    }
    
    fileprivate func tableViewEvent() {
        self.historyEvent()
        self.searchEvent()
        self.suggestionEvent()
    }
    
    fileprivate func suggestionEvent() {
        self.suggestionTableView.rx.modelSelected(UserPublic.self).map { $0.profile.name }.do(onNext: { [weak self] (name) in
            self?.controller?.addHistory(History.init(id: UUID().uuidString, text: name, timeInterval: Date().timeIntervalSince1970, type: .user))
        })
            .flatMap { SearchNetworkService.shared.historyAuthor(titles: [$0]).catchErrorJustReturn(()) }
        .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func historyEvent() {
        self.historyTableView
            .rx
            .modelSelected(History.self)
            .asDriver()
            .drive(onNext: { [weak self] (history) in
                self?.controller?.save(history: history)
                self?.controller?.delegate?.updateTextInSearchBar(text: history.text)
                self?.startSearch(with: history.text)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func totalResultEvent() {
        self.totalResult
            .bind { [weak self] (total) in
                self?.setupHeader(count: total)
                self?.searchTableView.reloadData()
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func searchEvent() {
        Observable.of(
            self.suggestionTableView.rx.modelSelected(UserPublic.self),
            self.searchTableView.rx.modelSelected(UserPublic.self)
        )
            .merge()
            .flatMapFirst { (userPublic) -> Observable<(UserPublic, UserPrivate?)> in
                return Observable<(UserPublic, UserPrivate?)>
                    .combineLatest(
                        Observable<UserPublic>.just(userPublic),
                        Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first },
                        resultSelector: { ($0, $1) }
                )
            }
            .subscribe(onNext: { [weak self] (userPublic, userPrivate) in
                switch userPublic.profile.userTypeFlag {
                case .normal:
                    if let userId = userPrivate?.id , userId == userPublic.profile.id {
                        let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                        vc.isShowButton.onNext(true)
                        vc.hidesBottomBarWhenPushed = true 
                        self?.controller?.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        self?.controller?.performSegue(withIdentifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: userPublic)
                    }
                    break
                case .bookstop:
                    let bookstop = Bookstop()
                    bookstop.id = userPublic.profile.id
                    bookstop.profile = userPublic.profile
                    self?.controller?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER, sender: bookstop)
                    break
                case .organization:
                    let bookstop = Bookstop()
                    bookstop.id = userPublic.profile.id
                    bookstop.profile = userPublic.profile
                    self?.controller?.performSegue(withIdentifier: "showBookstopOrganization", sender: bookstop)
                    break
                }
            })
            .disposed(by: self.disposeBag)
    }
}

extension SearchUserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == self.historyTableView.tag {
            return 0.11 * tableView.frame.height
        } else if tableView.tag == self.searchTableView.tag {
            let users = try! self.users.value()
            return UserResultTableViewCell.size(user: users[indexPath.row], in: self.searchTableView)
        } else {
            let users = try! self.suggestions.value()
            return SuggestionUserTableViewCell.size(user: users[indexPath.row].profile, in: self.suggestionTableView)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView.tag == self.searchTableView.tag {
            return self.header
        } else if tableView.tag == self.suggestionTableView.tag {
            let header = Bundle.main.loadNibNamed(Gat.View.HEADER, owner: self.controller, options: nil)?.first as? HeaderSearch
            header?.backgroundColor = .white
            header?.showView.isHidden = true
            header?.titleLabel.text = "Suggestion"
            header?.titleLabel.font = .systemFont(ofSize: 14.0, weight: .medium)
            header?.titleLabel.textColor = .black
            return header
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView.tag == self.searchTableView.tag {
            return 0.06 * tableView.frame.height
        } else if tableView.tag == self.suggestionTableView.tag {
            return 40.0
        } else {
            return 0.0
        }
    }
}

extension SearchUserViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        guard self.status == .search else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.searchTableView.contentOffset.y >= (self.searchTableView.contentSize.height - self.searchTableView.frame.height) {
            if transition.y < -70 {
                self.showSearch = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
                self.activeSearch.onNext(true)
            }
        }
    }
}
