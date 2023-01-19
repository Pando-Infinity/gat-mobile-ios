//
//  BorrowingRequestContainer.swift
//  gat
//
//  Created by Vũ Kiên on 26/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RealmSwift

class BorrowingRequestContainer: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var filterButton: UIButton!
    weak var profileViewController: ProfileViewController?
    var height: CGFloat = 0.0
    
    var showStatus: SearchState = .new
    fileprivate var datasources: RxTableViewSectionedReloadDataSource<SectionModel<String, BookRequest>>!
    let items: BehaviorSubject<[SectionModel<String, BookRequest>]> = .init(value: [])
    fileprivate let borrowStatus: BehaviorSubject<[RecordStatus]> = .init(value: [RecordStatus.waitConfirm, RecordStatus.contacting, RecordStatus.borrowing])
    fileprivate let lendStatus: BehaviorSubject<[RecordStatus]> = .init(value: [RecordStatus.waitConfirm, RecordStatus.contacting, RecordStatus.borrowing])
    let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.getData()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showStatus = .new
        self.page.onNext(1)
        self.filterButton.setTitle(Gat.Text.Filterable.FILTER_TITLE.localized(), for: .normal)
        self.searchTextField.attributedPlaceholder = .init(string: Gat.Text.SEARCH_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.getRequestInDatabase()
        self.getRequestInServer()
    }
    
    fileprivate func getRequestInDatabase() {
        Repository<BookRequest, BookRequestObject>
            .shared
            .getAll()
            .map {
                [
                    SectionModel<String, BookRequest>(model: Gat.Text.UserProfile.Request.REQUEST_INT_COMMING_TITLE, items: $0.filter { $0.recordType == .sharing}),
                    SectionModel<String, BookRequest>(model: Gat.Text.UserProfile.Request.REQUEST_OUT_GOING_TITLE, items: $0.filter { $0.recordType == .borrowing})
                ]
            }
            .subscribe(onNext: { [weak self] (items) in
                self?.items.onNext(items)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getRequestInServer() {
        self.borrowStatus.map { $0.map { $0.name } }.subscribe(onNext: {print($0)}).disposed(by: self.disposeBag)
        self.lendStatus.map { $0.map { $0.name } }.subscribe(onNext: { print($0) }).disposed(by: self.disposeBag)
        Observable<([RecordStatus], [RecordStatus], String?, Int, Bool)>
            .combineLatest(
                self.borrowStatus,
                self.lendStatus,
                self.searchTextField.rx.text.asObservable(),
                self.page,
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1, $2, $3, $4) }
            )
            .filter { $0.4 }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .map { ($0.0, $0.1, $0.2, $0.3) }
            .flatMap {
                RequestNetworkService
                    .shared
                    .record(borrowStatus: $0, lendStatus: $1, keyword: $2, page: $3)
                    .catchError { (error) -> Observable<[BookRequest]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .flatMapLatest { [weak self] (bookRequests) in self?.getBookInfoIfNeeded(bookRequests: bookRequests) ?? Observable.empty() }
            .flatMapLatest { [weak self] (bookRequests) in self?.getProfileIfNeeded(bookRequests: bookRequests) ?? Observable.empty() }
            .do(onNext: { [weak self] (bookRequests) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let value = try? self?.items.value(), var items = value, let status = self?.showStatus else {
                    return
                }
                let sharing = bookRequests.filter { $0.recordType == .sharing }
                let borrowing = bookRequests.filter { $0.recordType == .borrowing }
                switch status {
                case .new:
                    items[0].items = sharing
                    items[1].items = borrowing
                    break
                case .more:
                    items[0].items.append(contentsOf: sharing)
                    items[1].items.append(contentsOf: borrowing)
                    break
                }
                self?.items.onNext(items)
            })
            .flatMapLatest { Repository<BookRequest, BookRequestObject>.shared.save(objects: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getBookInfoIfNeeded(bookRequests: [BookRequest]) -> Observable<[BookRequest]> {
        if bookRequests.isEmpty { return Observable.just(bookRequests)}
        var list = [BookRequest]()
        return Observable<BookRequest>
            .from(bookRequests)
            .flatMapLatest({ (bookRequest) -> Observable<BookRequest> in
                return Observable<BookRequest>
                    .combineLatest(
                        Observable<BookRequest>.just(bookRequest),
                        Repository<BookInfo, BookInfoObject>.shared.getAll(predicateFormat: "editionId = %@", args: [bookRequest.book!.editionId]).map { $0.first },
                        resultSelector: { (bookRequest, bookInfo) -> BookRequest in
                            if let book = bookInfo {
                                bookRequest.book = book
                            }
                            return bookRequest
                    }
                )
            })
            .do(onNext: { (bookRequest) in
                list.append(bookRequest)
            })
            .filter { _ in list.count == bookRequests.count }
            .map { _ in list }
    }
    
    fileprivate func getProfileIfNeeded(bookRequests: [BookRequest]) -> Observable<[BookRequest]> {
        if bookRequests.isEmpty { return Observable.just(bookRequests) }
        var list = [BookRequest]()
        return Observable<BookRequest>
            .from(bookRequests)
            .flatMapLatest { (bookRequest) -> Observable<BookRequest> in
                return Observable<BookRequest>
                    .combineLatest(
                        Observable<BookRequest>.just(bookRequest),
                        Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                        Repository<Profile, ProfileObject>.shared.getAll(),
                        resultSelector: { (bookRequest, userPrivate, profiles) -> BookRequest in
                            if bookRequest.owner?.id == userPrivate.id {
                                bookRequest.owner = userPrivate.profile
                                bookRequest.recordType = .sharing
                                let profile = profiles.filter { $0.id == bookRequest.borrower!.id }.first
                                if profile != nil {
                                    bookRequest.borrower = profile
                                }
                            } else {
                                bookRequest.borrower = userPrivate.profile
                                bookRequest.recordType = .borrowing
                                let profile = profiles.filter { $0.id == bookRequest.owner!.id }.first
                                if profile != nil {
                                    bookRequest.owner = profile
                                }
                            }
                            return bookRequest
                    })
            }
            .do(onNext: { (bookRequest) in
                list.append(bookRequest)
            })
            .filter { _ in list.count == bookRequests.count }
            .map { _ in list }
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.setupTableView()
        self.setupLoading()
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.datasources = RxTableViewSectionedReloadDataSource<SectionModel<String, BookRequest>>.init(configureCell: { (datasource, tableView, indexPath, bookRequest) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "BorrowingRequestCell", for: indexPath) as! BorrowingRequestTableViewCell
            cell.controller = self
            cell.setup(bookRequest: bookRequest)
            return cell
        })
        self.items
            .bind(to: self.tableView.rx.items(dataSource: self.datasources))
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupLoading() {
        let url = Bundle.main.url(forResource: LOADING_GIF, withExtension: EXTENSION_GIF)
        self.loadingView.sd_setImage(with: url!)
        self.loadingView.isHidden = true
    }
    
    fileprivate func waiting(_ isWaiting: Bool) {
        self.loadingView.isHidden = !isWaiting
        self.tableView.isUserInteractionEnabled = !isWaiting
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.tableViewEvent()
        self.hideKeyboardEvent()
        self.filterButtonEvent()
    }
    
    fileprivate func filterButtonEvent() {
        self.filterButton.rx.tap.asObservable().subscribe(onNext: self.showFilterOption).disposed(by: self.disposeBag)
    }
    
    fileprivate func hideKeyboardEvent() {
        Observable.of(
            self.searchTextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
        )
            .merge()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchTextField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func tableViewEvent() {
        self.tableView
            .rx
            .itemSelected
            .asObservable()
            .flatMapLatest { [weak self] (indexPath) -> Observable<BookRequest> in
                guard let value = try? self?.items.value(), let items = value else {
                    return Observable.empty()
                }
                return Observable<BookRequest>.just(items[indexPath.section].items[indexPath.row])
            }
            .subscribe(onNext: { [weak self] (bookRequest) in
                if bookRequest.recordType == .sharing {
                    self?.profileViewController?.performSegue(withIdentifier: Gat.Segue.SHOW_REQUEST_DETAIL_O_IDENTIFIER, sender: bookRequest)
                } else {
                    if bookRequest.borrowType == .userWithUser {
                        self?.profileViewController?.performSegue(withIdentifier: Gat.Segue.SHOW_REQUEST_DETAIL_S_IDENTIFIER, sender: bookRequest)
                    } else if bookRequest.borrowType == .userWithBookstop {
                        self?.profileViewController?.performSegue(withIdentifier: "showRequestDetailBookstopOrganization", sender: bookRequest)
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    fileprivate func showFilterOption() {
        let storyboard = UIStoryboard(name: "FilterList", bundle: nil)
        let navigation = storyboard.instantiateViewController(withIdentifier: ListOptionFilterViewController.identifier) as! UINavigationController
        let filterVC = navigation.topViewController as! ListOptionFilterViewController
        filterVC.name.onNext(Gat.Text.Filterable.FILTER_BUTTON.localized())
        filterVC.items.onNext([
            (OptionFilter.request, [RequestBorrowBookFilter.borrow, RequestBorrowBookFilter.lend]),
            (OptionFilter.status, [RecordStatus.waitConfirm, RecordStatus.contacting, RecordStatus.borrowing, RecordStatus.other])
            ])
        if var borrow = try? self.borrowStatus.value(), var lend = try? self.lendStatus.value() {
            if borrow.contains(where: { $0.rawValue >= 4 }) {
                borrow.removeAll(where: { $0.rawValue >= 4 })
                borrow.append(.other)
            }
            if lend.contains(where: {$0.rawValue >= 4}) {
                lend.removeAll(where: {$0.rawValue >= 4})
                lend.append(.other)
            }
            var filterables: [(Filterable, [Filterable])] = []
            if !borrow.isEmpty && !lend.isEmpty {
                filterables.append((OptionFilter.request, [RequestBorrowBookFilter.borrow, RequestBorrowBookFilter.lend]))
                filterables.append((OptionFilter.status, borrow))
            } else if !borrow.isEmpty {
                filterables.append((OptionFilter.request, [RequestBorrowBookFilter.borrow]))
                filterables.append((OptionFilter.status, borrow))
            } else if !lend.isEmpty {
                filterables.append((OptionFilter.request, [RequestBorrowBookFilter.lend]))
                filterables.append((OptionFilter.status, lend))
            }
            filterVC.selected.onNext(filterables)
        }
        let sheetController = SheetViewController(controller: navigation, sizes: [.fixed(347), .fullScreen])
        sheetController.topCornersRadius = 20.0
        self.present(sheetController, animated: true, completion: nil)
        let selectFilter = filterVC.acceptSelect().map { $0 as! [(OptionFilter, [Filterable])] }
        
        let request = selectFilter.map { $0.first(where: { $0.0 == .request })?.1 as? [RequestBorrowBookFilter] }.filter { $0 != nil }.map { $0! }
        
        let status = selectFilter
            .map { $0.first(where: { $0.0 == .status})?.1 as? [RecordStatus] }
            .filter { $0 != nil }.map { $0! }
            .map { (list) -> [RecordStatus] in
                var array = list
                if array.contains(.other) {
                    array.removeAll(where: { $0 == .other})
                    array.append(contentsOf: [RecordStatus.completed, RecordStatus.rejected, RecordStatus.cancelled, RecordStatus.unreturned])
                }
                return array
            }
        
        let observer = Observable.combineLatest(request, status, resultSelector: { ($0, $1) })
        observer.map { (request, status) -> [RecordStatus] in
            if request.contains(.borrow) { return status } else { return [] }
            }.subscribe(onNext: self.borrowStatus.onNext).disposed(by: self.disposeBag)
        observer.map { (request, status) -> [RecordStatus] in
            if request.contains(.lend) { return status } else { return [] }
            }.subscribe(onNext: self.lendStatus.onNext).disposed(by: self.disposeBag)
    }
}

extension BorrowingRequestContainer: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let items = try? self.items.value() else {
            return UIView()
        }
        if items[section].items.isEmpty {
            return UIView()
        } else {
            let header = Bundle.main.loadNibNamed("ProfileHeader", owner: self, options: nil)?.first as? ProfileHeaderView
            header?.titleLabel.text = items[section].model.localized()
            return header

        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 0.08 * tableView.frame.width
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width * 0.22
    }
}

extension BorrowingRequestContainer {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.height {
            if transition.y < -70 {
                self.showStatus = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if Status.reachable.value {
            let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
            if scrollView.contentOffset.y == 0 {
                if transition.y > 100 {
                    self.showStatus = .new
                    self.page.onNext(1)
                }
            }
        }
//        self.profileViewController?.changeFrame(scrollView: scrollView)
    }
}

extension BorrowingRequestContainer {
    fileprivate enum RequestBorrowBookFilter: Int, CaseIterable {
        case borrow = 0
        case lend = 1
    }
    
    fileprivate enum OptionFilter: Int {
        case request = 0
        case status = 1
    }
}

extension BorrowingRequestContainer.OptionFilter: Filterable {
    var name: String {
        switch self {
        case .request: return Gat.Text.UserProfile.Request.REQUEST_TO_BORROW_BOOK_FILTER.localized()
        case .status: return Gat.Text.UserProfile.Request.STATUS_FILTER.localized()
        }
    }
    
    var value: Int { return self.rawValue }
}

extension BorrowingRequestContainer.RequestBorrowBookFilter: Filterable {
    var name: String {
        switch self {
        case .borrow: return Gat.Text.UserProfile.Request.REQUEST_OUT_GOING_TITLE.localized()
        case .lend: return Gat.Text.UserProfile.Request.REQUEST_INT_COMMING_TITLE.localized()
        }
    }
    
    var value: Int { return self.rawValue }
}

extension RecordStatus: Filterable {
    var name: String {
        switch self {
        case .borrowing: return Gat.Text.UserProfile.Request.BORROWING_STATUS.localized()
        case .cancelled: return Gat.Text.UserProfile.Request.CANCELLED_STATUS.localized()
        case .completed: return Gat.Text.UserProfile.Request.RETURNED_STATUS.localized()
        case .contacting: return Gat.Text.UserProfile.Request.CONTACTING_STATUS.localized()
        case .rejected: return Gat.Text.UserProfile.Request.REJECTED_STATUS.localized()
        case .unreturned: return Gat.Text.UserProfile.Request.UNRETURNED_STATUS.localized()
        case .waitConfirm: return Gat.Text.UserProfile.Request.WAITING_CONFIRM_STATUS.localized()
        case .onHold: return Gat.Text.UserProfile.Request.ON_HOLD_STATUS.localized()
        case .other: return Gat.Text.OTHER.localized()
        }
    }
    
    var value: Int { return self.rawValue }
}
