//
//  BookCaseViewController.swift
//  gat
//
//  Created by Vũ Kiên on 28/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BookCaseViewController: UIViewController {

    @IBOutlet weak var searchTextField: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIImageView!
    
    weak var bookstopController: BookStopViewController?
    var height: CGFloat = 0.0
    fileprivate let userSharingBooks = BehaviorSubject<[UserSharingBook]>(value: [])
    fileprivate let textSearch: BehaviorSubject<String?> = .init(value: nil)
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var statusShow: SearchState = .new
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.height = self.bookstopController!.backgroundHeightConstraint.multiplier * self.bookstopController!.view.frame.height
        self.setupUI()
        self.getData()
        self.event()
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.getTotal()
        self.getListBook()
    }
    
    fileprivate func getTotal() {
        self.bookstopController?
            .bookstop
            .filter { _ in Status.reachable.value }
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .totalBook(of: $0)
                    .catchErrorJustReturn(0)
            }
            .subscribe(onNext: { [weak self] (total) in
                self?.bookstopController?.bookstopTabView.configureBook(number: total)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getListBook() {
        Observable<(Bookstop, String?, Int, Bool)>
            .combineLatest(
                self.bookstopController?.bookstop ?? Observable.empty(),
                self.textSearch,
                self.page,
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1, $2, $3) }
            )
            .throttle(1.0, scheduler: MainScheduler.instance)
            .filter { (_, _, _, status) in status }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .map { (bookstop, text, page, _) in (bookstop, text, page) }
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .listBook(of: $0, searchKey: $1, option: .all, page: $2)
                    .catchError { (error) -> Observable<[UserSharingBook]> in
                        HandleError.default.showAlert(with: error)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { [weak self] (userSharingBooks) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let value = try? self?.userSharingBooks.value(), var list = value, let status = self?.statusShow else {
                    return
                }
                switch status {
                case .new:
                    list = userSharingBooks
                    break
                case .more:
                    list.append(contentsOf: userSharingBooks)
                    break
                }
                self?.userSharingBooks.onNext(list)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        let textFieldInsideSearchBar = searchTextField.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = .black
        self.searchTextField.placeholder = Gat.Text.Bookstop.SEARCH_BOOK_PLACEHOLDER.localized()
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.userSharingBooks
            .bind(to: self.tableView.rx.items(cellIdentifier: Gat.Cell.IDENTIFIER_SHARING_BOOKSTOP, cellType: SharingBookStopTableViewCell.self))
            { [weak self] (row, userSharingBook, cell) in
                cell.controller = self
                cell.setup(userSharingBook: userSharingBook)
            }
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.searchBarEvent()
    }
    
    fileprivate func searchBarEvent() {
        self.searchTextField
            .rx
            .textDidBeginEditing
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchTextField.showsCancelButton = true
            })
            .disposed(by: self.disposeBag)
        
        self.searchTextField
            .rx
            .searchButtonClicked
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchTextField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
        
        self.searchTextField
            .rx
            .cancelButtonClicked
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchTextField.text = ""
                self?.searchTextField.resignFirstResponder()
                self?.searchTextField.showsCancelButton = false
                self?.textSearch.onNext("")
            })
            .disposed(by: self.disposeBag)
        
        self.searchTextField
            .rx
            .text
            .asObservable()
            .subscribe(self.textSearch)
            .disposed(by: self.disposeBag)
    }
}

extension BookCaseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width * 0.28
    }
}

extension BookCaseViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= (tableView.contentSize.height - self.tableView.frame.height) {
            if transition.y < -100 {
                self.statusShow = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if Status.reachable.value {
            let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
            if scrollView.contentOffset.y == 0 {
                if transition.y > 150 {
                    self.statusShow = .new
                    self.page.onNext(1)
                }
            }
        }
        let relativeYOffset = scrollView.contentOffset.y - self.bookstopController!.backgroundHeightConstraint.multiplier * self.bookstopController!.view.frame.height
        self.height = max(-relativeYOffset, self.bookstopController!.view.frame.height * self.bookstopController!.headerHeightConstraint.multiplier) < self.bookstopController!.backgroundHeightConstraint.multiplier * self.bookstopController!.view.frame.height ? max(-relativeYOffset, self.bookstopController!.view.frame.height * self.bookstopController!.headerHeightConstraint.multiplier) : self.bookstopController!.backgroundHeightConstraint.multiplier * self.bookstopController!.view.frame.height
        self.bookstopController?.view.layoutIfNeeded()
        self.bookstopController?.changeFrameProfileView(height: self.height)
    }
}
