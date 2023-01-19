//
//  SearchBookViewController.swift
//  gat
//
//  Created by Vũ Kiên on 03/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SearchBookViewController: UIViewController {
    
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var suggestionTableView: UITableView!
    @IBOutlet weak var loadingView: UIImageView!
    
    fileprivate let addButton: UIButton = .init()
    fileprivate var easyTip: EasyTipView!
    
    var showGuideline = false
    let textSearch = BehaviorSubject<String>(value: "")
    let activeSearch = BehaviorSubject<Bool>(value: false)
    var showSearch: SearchState = .new
    let page = BehaviorSubject<Int>(value: 1)
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
        print(self.showGuideline)

        self.setupUI()
        self.getData()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addButton.setAttributedTitle(NSAttributedString(string: Gat.Text.Search.ADD_NEW_BOOK_TITLE.localized(), attributes: [.font: UIFont.systemFont(ofSize: 15.0), .foregroundColor: UIColor.white]), for: .normal)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.addButton.frame = .init(x: 16.0, y: self.view.frame.height - 56.0, width: UIScreen.main.bounds.width - 32.0, height: 40.0)
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.getHistory()
        self.searchBook()
        self.getSuggestion()
    }
    
    func getHistory() {
        Observable.just(Session.shared.isAuthenticated).filter { $0 }
            .flatMapLatest { (_) -> Observable<[History]> in
                return Repository<History, HistoryObject>.shared.getAll(predicateFormat: "type = %@", args: [HistoryType.book.rawValue], sortBy: "date", ascending: false)
            }
            .do(onNext: { [weak self] (histories) in
                self?.histories.onNext(histories)
            })
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.waitInteracter(true)
            })
            .flatMapLatest { _ in HistoryNetworkService.shared.searchHistory(type: .book).catchErrorJustReturn([]) }
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
            .flatMap { SearchSuggestionService.shared.suggestionTitle(text: $0).catchErrorJustReturn([]) }
            .subscribe(onNext: self.suggestions.onNext)
            .disposed(by: self.disposeBag)
            
    }
    
    fileprivate func searchBook() {
        Observable<(String, Int, Bool)>
            .combineLatest(self.textSearch.asObservable(), self.page.asObservable(), self.activeSearch.asObservable(), resultSelector: {($0, $1, $2)})
            .filter { (_, _, active) in active }
            .filter { (text, _, _) in !text.isEmpty }
            .filter { _ in  Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.waitInteracter(true)
            })
            .map { (text, page, _ ) in (text, page) }
            .flatMapLatest({ [weak self] (title, page) -> Observable<([BookSharing], Int)> in
                return SearchNetworkService.shared
                    .book(title: title, page: page)
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
                guard let bookSharings = try? self?.books.value(), var books = bookSharings, let status = self?.showSearch else { return }
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
    }
    
    fileprivate func refreshHistory() {
        Repository<History, HistoryObject>.shared.getAll(predicateFormat: "type = %@", args: [HistoryType.book.rawValue], sortBy: "date", ascending: false).subscribe(onNext: self.histories.onNext).disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.setupTableView()
        self.loadingUI()
        self.books.filter { !$0.isEmpty }
            .subscribe(onNext: { [weak self] (_) in
                self?.setupTipView()
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTipView() {
        print(self.showGuideline)
        guard Repository<UserPrivate, UserPrivateObject>.shared.get() != nil, self.showGuideline else { return }
        guard let flow = GuidelineService.shared.addBook, flow.steps[0].completed, flow.steps[1].completed, !flow.steps[2].completed else { return }
        self.configTipView()
    }
    
    fileprivate func configTipView() {
        self.view.layoutIfNeeded()
        var preferences = EasyTipView.Preferences()
        preferences.drawing.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        preferences.drawing.backgroundColorTip = .white
        preferences.drawing.shadowColor = #colorLiteral(red: 0.4705882353, green: 0.4705882353, blue: 0.4705882353, alpha: 1)
        preferences.drawing.shadowOpacity = 0.5
        preferences.drawing.arrowPosition = .top
        preferences.positioning.maxWidth = UIScreen.main.bounds.width - 32.0
        preferences.drawing.arrowHeight = 16.0
        preferences.positioning.bubbleHInset = 0
        preferences.positioning.bubbleVInset = 0
        preferences.positioning.contentHInset = 0
        preferences.positioning.contentVInset = 0
        preferences.animating.dismissOnTap = true
        
        let rectOfCellInTableView = self.searchTableView.rectForRow(at: .init(row: 0, section: 0))
        let rectOfCellInSuperview = self.searchTableView.convert(rectOfCellInTableView, to: self.tabBarController!.view)
        let clipPath = UIBezierPath(rect: rectOfCellInSuperview)
        let easyTip = EasyTipView(view: self.configAlertTip(), forcus: self.searchTableView.visibleCells[0], clipPath: clipPath, preferences: preferences, delegate: self)
        easyTip.show(withinSuperview: self.tabBarController!.view)
        self.easyTip = easyTip
    }
    
    fileprivate func configAlertTip() -> UIView {
        let alert = UIView(frame: .init(origin: .zero, size: .init(width: self.searchTableView.frame.width - 32.0, height: 100.0)))
        let label = UILabel()
        label.numberOfLines = 0
        label.frame.origin = .init(x: alert.bounds.origin.x + 8.0, y: alert.bounds.origin.y + 16.0)
        alert.addSubview(label)
        
        label.frame.size.width = alert.frame.width - 16.0
        label.preferredMaxLayoutWidth = alert.frame.width - 16.0
        
        let text = String(format: Gat.Text.Guideline.ADD_BOOK_OR_BORROW_BOOK.localized(), Gat.Text.Guideline.ADD_TITLE.localized(), Gat.Text.Guideline.BORROW_TITLE.localized())
        
        let attributedString = NSMutableAttributedString(string: text, attributes: [
          .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
          .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1),
          .kern: 0.17
        ])
        attributedString.addAttributes([
          .font: UIFont.systemFont(ofSize: 14.0, weight: .semibold),
          .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        ], range: (text as NSString).range(of: Gat.Text.Guideline.ADD_TITLE.localized()))
        attributedString.addAttributes([
          .font: UIFont.systemFont(ofSize: 14.0, weight: .semibold),
          .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        ], range: (text as NSString).range(of: Gat.Text.Guideline.BORROW_TITLE.localized()))
        label.attributedText = attributedString
        
        let sizeLabel = label.sizeThatFits(.init(width: label.frame.size.width, height: .infinity))
        label.frame.size.height = sizeLabel.height
        
        let seperateView = UIView(frame: .init(origin: .init(x: 0.0, y: label.frame.origin.y + sizeLabel.height + 16.0), size: .init(width: alert.frame.width, height: 1.0)))
        seperateView.backgroundColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        
        alert.addSubview(seperateView)
        
        let button = UIButton(frame: .init(x: 0.0, y: seperateView.frame.origin.y + seperateView.frame.height, width: alert.frame.width, height: 40.0))
        button.setAttributedTitle(.init(string: Gat.Text.Guideline.COMPLETE.localized(), attributes: [.font: UIFont.systemFont(ofSize: 16.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)]), for: .normal)
        alert.addSubview(button)
        alert.frame.size.height = button.frame.origin.y + button.frame.height
        
        button.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.easyTip.dismiss(focus: true)
            GuidelineService.shared.complete(flow: GuidelineService.shared.addBook!)
        }).disposed(by: self.disposeBag)
        
        return alert
    }
    
    
    fileprivate func setupTableView() {
        self.setupSearchBookTableView()
        self.setupHistoriesTableView()
        self.setupSuggestionTableView()
        self.setupAddButton()
    }
    
    fileprivate func setupAddButton() {
        self.view.layoutIfNeeded()
        self.addButton.backgroundColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        self.addButton.cornerRadius(radius: 20.0)
        self.view.addSubview(self.addButton)
        self.view.bringSubviewToFront(self.addButton)
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
                cell.setupHistory(label: history.text, index: 0)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSearchBookTableView() {
        self.searchTableView.delegate = self
        self.registerCell()
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
    
    fileprivate func registerCell() {
        let nib1 = UINib(nibName: "BookDetailTableViewCell", bundle: nil)
        self.searchTableView.register(nib1, forCellReuseIdentifier: "bookCell")
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
            .do(onNext: { [weak self] (book) in
                self?.controller?.addHistory(History(id: UUID().uuidString, text: book.title, timeInterval: Date().timeIntervalSince1970, type: .book))
                self?.refreshHistory()
            })
            .flatMap { SearchNetworkService.shared.historyBook(titles: [$0.title]).catchErrorJustReturn(()) }
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

extension SearchBookViewController: UITableViewDelegate {
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

extension SearchBookViewController: BookDetailCellDelegate {
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


extension SearchBookViewController {
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

extension SearchBookViewController: EasyTipViewDelegate {
    func easyTipViewDidDismiss(_ tipView: EasyTipView, forcus: Bool) {
        GuidelineService.shared.complete(flow: GuidelineService.shared.addBook!)
        guard forcus else { return }
//        guard let books = try? self.books.value() else { return }
//        self.controller?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: books[0].info)

    }
}
