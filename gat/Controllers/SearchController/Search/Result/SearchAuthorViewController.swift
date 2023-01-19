//
//  SearchAuthorViewController.swift
//  gat
//
//  Created by Vũ Kiên on 03/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SearchAuthorViewController: UIViewController {
    
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var suggestionTableView: UITableView!
    @IBOutlet weak var loadingView: UIImageView!
    
    fileprivate let addButton: UIButton = .init()

    let textSearch = BehaviorSubject<String>(value: "")
    let activeSearch = BehaviorSubject<Bool>(value: false)
    let page = BehaviorSubject<Int>(value: 1)
    var showSearch: SearchState = .new
    var status: ShowState = .history
    weak var controller: SearchViewController?
    
    fileprivate let histories = BehaviorSubject<[History]>(value: [])
    fileprivate let books = BehaviorSubject<[BookSharing]>(value: [])
    fileprivate let suggestions: BehaviorSubject<[BookInfo]> = .init(value: [])
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addButton.setAttributedTitle(NSAttributedString(string: Gat.Text.Search.ADD_NEW_BOOK_TITLE.localized(), attributes: [.font: UIFont.systemFont(ofSize: 15.0), .foregroundColor: UIColor.white]), for: .normal)
    }

    //MARK: - Data
    fileprivate func getData() {
        self.getHistory()
        self.searchAuthor()
        self.getSuggestion()
    }
    
    func getHistory() {
        Observable.just(Session.shared.isAuthenticated).filter { $0 }
            .flatMapLatest { _ in Repository<History, HistoryObject>.shared.getAll(predicateFormat: "type = %@", args: [HistoryType.author.rawValue]) }
            .do(onNext: { [weak self] (histories) in
                self?.histories.onNext(histories)
            })
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.waitInteracter(true)
            })
            .flatMapLatest { _ in HistoryNetworkService.shared.searchHistory(type: .author).catchErrorJustReturn([]) }
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
            .flatMap { SearchSuggestionService.shared.suggestionAuthor(text: $0).catchErrorJustReturn([]) }
            .subscribe(onNext: self.suggestions.onNext)
            .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func searchAuthor() {
        Observable<(String, Int, Bool)>
            .combineLatest(self.textSearch.asObservable(), self.page.asObservable(), self.activeSearch.asObservable(), resultSelector: {($0, $1, $2)})
            .filter { (_, _, active) in active }
            .filter { (text, _, _) in !text.isEmpty }
            .filter { _ in  Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.waitInteracter(true)
            })
            .map { (text, page, _ ) in (text, page) }
            .flatMapLatest({ [weak self] (name, page) -> Observable<([BookSharing], Int)> in
                return SearchNetworkService.shared.author(name: name, page: page)
                    .catchError({ [weak self] (error) -> Observable<([BookSharing], Int)> in
                        self?.waitInteracter(false)
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            })
            .subscribe(onNext: { [weak self] (list, total) in
                self?.waitInteracter(false)
                self?.status = .search
                self?.activeSearch.onNext(false)
                self?.totalResult.onNext(total)
                guard let bookSharings = try? self?.books.value(), var books = bookSharings, let status = self?.showSearch else {
                    return
                }
                if status == .new && list.isEmpty {
                    if let button = self?.addButton {
                        self?.searchTableView.addSubview(button)
                    }
                }
                switch status {
                case .new:
                    books = list
                    break
                case .more:
                    books.append(contentsOf: list)
                    break
                }
                self?.books.onNext(books)
            })
            .disposed(by: self.disposeBag)
    }
    
    func startSearch(with title: String) {
        self.status = .search
        self.showSearch = .new
        self.page.onNext(1)
        self.textSearch.onNext(title)
        self.activeSearch.onNext(true)
        self.refreshHistory()
        self.addButton.removeFromSuperview()
    }
    
    fileprivate func refreshHistory() {
        Repository<History, HistoryObject>.shared.getAll(predicateFormat: "type = %@", args: [HistoryType.author.rawValue]).subscribe(onNext: self.histories.onNext).disposed(by: self.disposeBag)
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
        self.setupAddButton()
    }
    
    fileprivate func setupAddButton() {
        self.view.layoutIfNeeded()
        self.addButton.frame = .init(x: 16.0, y: self.searchTableView.frame.height * 0.06, width: UIScreen.main.bounds.width - 32.0, height: 40.0)
        self.addButton.backgroundColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        self.addButton.cornerRadius(radius: 20.0)
    }
    
    fileprivate func setupSuggestionTableView() {
        self.suggestionTableView.delegate = self
        self.suggestionTableView.register(UINib.init(nibName: SuggestionBookTableViewCell.className, bundle: nil), forCellReuseIdentifier: SuggestionBookTableViewCell.identifier)
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
            .bind(to: self.suggestionTableView.rx.items(cellIdentifier: SuggestionBookTableViewCell.identifier, cellType: SuggestionBookTableViewCell.self))
            { (index, book, cell) in
                cell.book.accept(book)
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
                cell.setupHistory(label: history.text, index: 1)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSearchTableView() {
        self.searchTableView.delegate = self
        let nib = UINib(nibName: "BookDetailTableViewCell", bundle: nil)
        self.searchTableView.register(nib, forCellReuseIdentifier: "bookCell")
        self.searchTableView.tableFooterView = UIView()
        self.books
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
            .bind(to: self.searchTableView.rx.items(cellIdentifier: "bookCell", cellType: BookDetailTableViewCell.self))
            { [weak self] (row, book, cell) in
                cell.delegate = self
                cell.getInfo(bookSharing: book)
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
        self.historyTableViewEvent()
        self.searchTableViewEvent()
        self.suggestionEvent()
        self.totalResultEvent()
        self.addButtonEvent()
        LanguageHelper.changeEvent.filter { [weak self] _ in self?.status == .search }.flatMap { [weak self] (_) -> Observable<Int> in
            guard let result = self?.totalResult else { return Observable.empty() }
            return Observable<Int>.from(optional: try? result.value())
            }.subscribe(onNext: self.totalResult.onNext).disposed(by: self.disposeBag)
    }
    
    fileprivate func suggestionEvent() {
        self.suggestionTableView.rx
            .modelSelected(BookInfo.self)
            .filter { !$0.author.isEmpty }
            .do(onNext: { [weak self] (book) in
                self?.controller?.addHistory(History(id: UUID().uuidString, text: book.author, timeInterval: Date().timeIntervalSince1970, type: .author))
                self?.refreshHistory()
            })
            .flatMap { SearchNetworkService.shared.historyAuthor(titles: [$0.author]).catchErrorJustReturn(()) }
            .subscribe()
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
    
    fileprivate func historyTableViewEvent() {
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
    
    fileprivate func searchTableViewEvent() {
       Observable.of(
            self.suggestionTableView.rx.modelSelected(BookInfo.self).asObservable(),
            self.searchTableView.rx.modelSelected(BookSharing.self).map { $0.info! }
        )
        .merge()
            .subscribe(onNext: { [weak self] (book) in
                self?.controller?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: book)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func addButtonEvent() {
        self.addButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            guard let text = try? self?.textSearch.value() else { return }
            self?.controller?.performSegue(withIdentifier: AddNewBookViewController.segueIdentifier, sender: text)
        }).disposed(by: self.disposeBag)
    }
}

extension SearchAuthorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == self.historyTableView.tag {
            return 0.11 * tableView.frame.height
        } else if tableView.tag == self.searchTableView.tag {
            return 0.3 * tableView.frame.height
        } else {
            return 116.0
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

extension SearchAuthorViewController: BookDetailCellDelegate {
    func show(viewController: UIViewController) {
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func update(bookSharing: BookSharing) {
        do {
            let books = try self.books.value()
            books.filter { $0.info?.editionId == bookSharing.info?.editionId }.first?.info?.saving = bookSharing.info!.saving
            self.books.onNext(books)
        } catch {
            
        }
    }
}

extension SearchAuthorViewController {
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
