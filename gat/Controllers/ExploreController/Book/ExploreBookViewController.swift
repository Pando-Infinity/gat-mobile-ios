//
//  ExploreBookViewController.swift
//  gat
//
//  Created by Vũ Kiên on 06/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import CoreLocation

class ExploreBookViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    let editionIds: BehaviorSubject<[Int]> = .init(value: [])
    let mode: BehaviorSubject<SuggestBookByModeRequest.SuggestBookMode?> = .init(value: nil)
    let titleText: BehaviorSubject<String> = .init(value: Gat.Text.TopBorrowBook.TITLE_LABEL.localized())
    fileprivate let disposeBag = DisposeBag()
    fileprivate let books = BehaviorSubject<[BookSharing]>(value: [])
    fileprivate let page = BehaviorSubject<Int>(value: 1)
    fileprivate var showStatus = SearchState.new
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        self.getDataLocal()
        self.getDataServer()
    }
    
    fileprivate func getDataLocal() {
        Observable<Bool>
            .combineLatest(self.editionIds, self.mode, resultSelector: {$0.isEmpty && $1 == nil })
            .filter { $0 }
            .flatMap { _ in Repository<BookSharing, BookSharingObject>.shared.getAll() }
            .do(onNext: { [weak self] (bookSharings) in
                self?.books.onNext(bookSharings)
            })
            .flatMapLatest { Repository<BookSharing, BookSharingObject>.shared.delete(objects: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getDataServer() {
        Observable
            .of(self.getTopBorrow(), self.getBookFromEditionId(), self.getBookFromMode())
            .merge()
            .do(onNext: { [weak self] (list) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let status = self?.showStatus, let value = try? self?.books.value(), var books = value else {
                    return
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
            .flatMapLatest { Repository<BookSharing, BookSharingObject>.shared.save(objects: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getTopBorrow() -> Observable<[BookSharing]> {
        return Observable<(Bool, Int)>
            .combineLatest(self.editionIds, self.mode, self.page, resultSelector: {($0.isEmpty && $1 == nil, $2)})
            .filter { $0.0 }
            .filter { _ in Status.reachable.value }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .map { (_, page) in page }
            .flatMapLatest {
                BookNetworkService.shared
                    .topBorrow(previousDay: Int(AppConfig.sharedConfig.config(item: "previous_days")!)!, page: $0, per_page: 10)
                    .catchError({ (error) -> Observable<[BookSharing]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
        }
    }
    
    fileprivate func getBookFromEditionId() -> Observable<[BookSharing]> {
        return self.editionIds
            .filter { !$0.isEmpty }
            .filter { _ in Status.reachable.value }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap {
                BookNetworkService
                    .shared
                    .infos(editions: $0)
                    .catchError({ (error) -> Observable<[BookSharing]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
    }
    
    fileprivate func getBookFromMode() -> Observable<[BookSharing]> {
        return Observable<(SuggestBookByModeRequest.SuggestBookMode?, Int)>
            .combineLatest(self.mode, self.page, resultSelector: {($0, $1)})
            .filter { $0.0 != nil }
            .withLatestFrom(self.getLocation(), resultSelector: { ($0.0!, $1, $0.1) })
            .filter { _ in Status.reachable.value }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap { (mode, location, page) -> Observable<[BookSharing]> in
                return BookNetworkService
                    .shared
                    .sugesst(mode: mode, previousDays: Int(AppConfig.sharedConfig.config(item: "previous_days")!)!, location: location, page: page)
                    .catchError({ (error) -> Observable<[BookSharing]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
        }
    }
    
    fileprivate func getLocation() -> Observable<CLLocationCoordinate2D> {
        return LocationManager
            .manager
            .location
            .catchErrorJustReturn(CLLocationCoordinate2D())
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleText.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.registerCell()
        self.setupTableView()
    }
    
    fileprivate func registerCell() {
        let nib = UINib(nibName: "BookDetailTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "bookCell")
    }
    
    fileprivate func setupTableView() {
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.books
            .asObservable()
            .bind(to: self.tableView.rx.items(cellIdentifier: "bookCell", cellType: BookDetailTableViewCell.self))
            { [weak self] (index, book, cell) in
                cell.delegate = self
                cell.bookSharing.onNext(book)
            }
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.backEvent()
        self.tableViewEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx.controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func tableViewEvent() {
        self.tableView
            .rx
            .modelSelected(BookSharing.self)
            .asDriver()
            .drive(onNext: { [weak self] (bookSharing) in
                self?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: bookSharing.info)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        }
    }

}

extension ExploreBookViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 0.25 * tableView.frame.height
    }
}

extension ExploreBookViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else { return }
        guard let editionIds = try? self.editionIds.value(), editionIds.isEmpty else { return }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.height {
            if transition.y < -70 {
                self.showStatus = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard Status.reachable.value else { return }
        guard let editionIds = try? self.editionIds.value(), editionIds.isEmpty else { return }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if scrollView.contentOffset.y == 0 {
            if transition.y > 100 {
                self.showStatus = .new
                self.page.onNext(1)
            }
        }
    }
}

extension ExploreBookViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension ExploreBookViewController: BookDetailCellDelegate {
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
