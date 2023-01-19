//
//  SharingBookContainerControllerViewController.swift
//  gat
//
//  Created by Vũ Kiên on 02/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SharingBookContainerController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var searchtextField: UITextField!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    
    weak var userVistorController: UserVistorViewController?
    var height: CGFloat = 0.0
    
    fileprivate let userSharingBooks: BehaviorSubject<[UserSharingBook]> = .init(value: [])
    fileprivate let option: BehaviorSubject<[SharingBookVisitorUserRequest.FilterOption]> = .init(value: SharingBookVisitorUserRequest.FilterOption.allCases)
    fileprivate var showStatus: SearchState = .new
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.height = self.userVistorController!.backgroundHeightConstraint.multiplier * self.userVistorController!.view.frame.height
        self.setupUI()
        self.getData()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.getList()
        self.getTotal()
    }
    
    fileprivate func getList() {
        self.option.map { _ in [UserSharingBook]() }.subscribe(onNext: self.userSharingBooks.onNext).disposed(by: self.disposeBag)
        Observable<(UserPublic, [SharingBookVisitorUserRequest.FilterOption], String?, Int, Bool)>
            .combineLatest(
                self.userVistorController!.userPublic,
                self.option,
                self.searchtextField.rx.text.asObservable(),
                self.page,
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1, $2, $3, $4) }
            )
            .filter { $0.4 }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .map { ($0.0, $0.1, $0.2, $0.3 )}
            .filter { !$0.1.isEmpty }
            .flatMap {
                BookNetworkService
                    .shared
                    .sharing(of: $0.profile, options: $1, keyword: $2, page: $3)
                    .catchError({ (error) -> Observable<[UserSharingBook]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .subscribe(onNext: { [weak self] (userSharingBooks) in
                guard let value = try? self?.userSharingBooks.value(), var list = value, let status = self?.showStatus else {
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
    
    fileprivate func getTotal() {
        Observable<(UserPublic, Bool)>
            .combineLatest(
                self.userVistorController?.userPublic ?? Observable.empty(),
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1) }
            )
            .filter { $0.1 }
            .map { $0.0 }
            .flatMap {
                BookNetworkService.shared.totalSharing(of: $0.profile).catchErrorJustReturn(0)
            }
            .subscribe(onNext: { [weak self] (total) in
                self?.userVistorController?.vistorUserTabView.configureBookSharing(total: total)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.searchtextField.attributedPlaceholder = .init(string: Gat.Text.SEARCH_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.filterButton.setTitle(Gat.Text.Filterable.FILTER_TITLE.localized(), for: .normal)
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.userSharingBooks
            .bind(to: self.tableView.rx.items(cellIdentifier: "vistorUserSharingBookCell", cellType: VistorUserSharingBookTableViewCell.self))
            { [weak self] (index, userSharingBook, cell) in
                cell.controller = self
                cell.setup(userSharingBook: userSharingBook)
            }
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.tableSelectedEvent()
        self.hideKeyboardEvent()
        self.filterEvent()
    }
    
    fileprivate func filterEvent() {
        self.filterButton.rx.tap.asObservable().subscribe(onNext: self.showFilterOption).disposed(by: self.disposeBag)
    }
    
    fileprivate func hideKeyboardEvent() {
        Observable.of(
            self.searchtextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
        )
            .merge()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchtextField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func tableSelectedEvent() {
        self.tableView
            .rx
            .modelSelected(UserSharingBook.self)
            .map { $0.request }
            .filter { $0 != nil }
            .subscribe(onNext: { [weak self] (request) in
                self?.userVistorController?.performSegue(withIdentifier: Gat.Segue.SHOW_REQUEST_DETAIL_S_IDENTIFIER, sender: request)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    fileprivate func showFilterOption() {
        let storyboard = UIStoryboard(name: "FilterList", bundle: nil)
        let filterVC = storyboard.instantiateViewController(withIdentifier: FilterListViewController.className) as! FilterListViewController
        filterVC.name.onNext(Gat.Text.Filterable.FILTER_BUTTON.localized())
        filterVC.items.onNext(SharingBookVisitorUserRequest.FilterOption.allCases)
        if let value = try? self.option.value() {
            filterVC.selected.onNext(value)
        }
        let sheetController = SheetViewController(controller: filterVC, sizes: [.fixed(347), .fullScreen])
        sheetController.topCornersRadius = 20.0
        self.present(sheetController, animated: true, completion: nil)
        filterVC.acceptSelect().map { $0.map { $0 as! SharingBookVisitorUserRequest.FilterOption} }.subscribe(onNext: self.option.onNext).disposed(by: self.disposeBag)
    }
}

extension SharingBookContainerController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width / 4.0
    }
}

extension SharingBookContainerController {
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
//        let relativeYOffset = scrollView.contentOffset.y - self.userVistorController!.backgroundHeightConstraint.multiplier * self.userVistorController!.view.frame.height
//        self.height = max(-relativeYOffset, self.userVistorController!.view.frame.height * self.userVistorController!.headerHeightConstraint.multiplier) < self.userVistorController!.backgroundHeightConstraint.multiplier * self.userVistorController!.view.frame.height ? max(-relativeYOffset, self.userVistorController!.view.frame.height * self.userVistorController!.headerHeightConstraint.multiplier) : self.userVistorController!.backgroundHeightConstraint.multiplier * self.userVistorController!.view.frame.height
//        self.userVistorController?.view.layoutIfNeeded()
//        self.userVistorController?.changeFrameProfileView(height: self.height)
    }
}

extension SharingBookVisitorUserRequest.FilterOption: Filterable {
    var name: String {
        switch self {
        case .available: return Gat.Text.Filterable.AVAILABLE_BOOK.localized()
        case .notAvailable: return Gat.Text.Filterable.NOT_AVAILABLE_BOOK.localized()
        }
    }
    
    var value: Int { return self.rawValue }
}
