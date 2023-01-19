//
//  ListReviewVistorUserViewController.swift
//  gat
//
//  Created by Vũ Kiên on 12/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class ListReviewVistorUserViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var filterButton: UIButton!
    
    weak var userVistorController: UserVistorViewController?
    var height: CGFloat = 0.0
    
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var showStatus: SearchState = .new
    fileprivate let reviews: BehaviorSubject<[Review]> = .init(value: [])
    fileprivate let option: BehaviorSubject<ListEvaluationRequest.EvaluationFilterOption?> = .init(value: ListEvaluationRequest.EvaluationFilterOption.all)
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        self.height = self.userVistorController!.backgroundHeightConstraint.multiplier * self.userVistorController!.view.frame.height
        self.setupUI()
        self.getData()
        self.event()
    }

    //MARK: - Data
    fileprivate func getData() {
        self.getListReview()
        self.getTotal()
    }
    
    fileprivate func getListReview() {
        self.option.filter { $0 == nil }.map { _ in [Review]() }.subscribe(onNext: self.reviews.onNext).disposed(by: self.disposeBag)
        Observable<(UserPublic, ListEvaluationRequest.EvaluationFilterOption?, String?, Int, Bool)>
            .combineLatest(
                self.userVistorController?.userPublic ?? Observable.empty(),
                self.option,
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
            .filter { $0.1 != nil }
            .map { ($0.0, $0.1!, $0.2, $0.3)}
            .flatMap {
                ReviewNetworkService
                    .shared
                    .reviews(of: $0.profile, option: $1, keyword: $2, page: $3)
                    .catchError { (error) -> Observable<[Review]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                }
            }
            .subscribe(onNext: { [weak self] (list) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let value = try? self?.reviews.value(), var reviews = value, let status = self?.showStatus else {
                    return
                }
                switch status {
                case .new:
                    reviews = list
                    break
                case .more:
                    reviews.append(contentsOf: list)
                    break
                }
                self?.reviews.onNext(reviews)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getTotal() {
        Observable<(UserPublic, Bool)>
            .combineLatest(self.userVistorController?.userPublic ?? Observable.empty(), Status.reachable.asObservable(), resultSelector: { ($0, $1) })
            .filter { $0.1 }
            .map { $0.0 }
            .flatMap {
                PostService.shared
                    .getTotalUserPost(userId: $0.profile.id, pageNum: 1)
                    .catchErrorJustReturn(0)
            }
            .subscribe(onNext: { [weak self] (total) in
                self?.userVistorController?.vistorUserTabView.configureReviewBook(total: total)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.searchTextField.attributedPlaceholder = .init(string: Gat.Text.SEARCH_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.filterButton.setTitle(Gat.Text.Filterable.FILTER_TITLE.localized(), for: .normal)
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.reviews
            .bind(to: self.tableView.rx.items(cellIdentifier: "reviewUserVistorCell", cellType: ReviewUserVistorTableViewCell.self))
            { [weak self] (index, review, cell) in
                cell.controller = self
                cell.setup(review: review)
            }
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.hideKeyboardEvent()
        self.filterEvent()
    }
    
    fileprivate func filterEvent() {
        self.filterButton.rx.tap.asObservable().subscribe(onNext: self.showFilterOption).disposed(by: self.disposeBag)
    }
    
    fileprivate func hideKeyboardEvent() {
        Observable.of(
            self.searchTextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
            )
            .merge()
            .subscribe({ [weak self] (_) in
                self?.searchTextField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    fileprivate func showFilterOption() {
        let storyboard = UIStoryboard(name: "FilterList", bundle: nil)
        let filterVC = storyboard.instantiateViewController(withIdentifier: FilterListViewController.className) as! FilterListViewController
        filterVC.name.onNext(Gat.Text.Filterable.FILTER_BUTTON.localized())
        filterVC.items.onNext([ListEvaluationRequest.EvaluationFilterOption.empty, ListEvaluationRequest.EvaluationFilterOption.notEmpty])
        if let value = try? self.option.value() {
            if value == .all {
                filterVC.selected.onNext([ListEvaluationRequest.EvaluationFilterOption.empty, ListEvaluationRequest.EvaluationFilterOption.notEmpty])
            } else if value != nil {
                filterVC.selected.onNext([value!])
            }
        }
        let sheetController = SheetViewController(controller: filterVC, sizes: [.fixed(347), .fullScreen])
        sheetController.topCornersRadius = 20.0
        self.present(sheetController, animated: true, completion: nil)
        filterVC.acceptSelect().map { $0.map { $0 as! ListEvaluationRequest.EvaluationFilterOption } }.map { (options) -> ListEvaluationRequest.EvaluationFilterOption? in
            if options.count == [ListEvaluationRequest.EvaluationFilterOption.empty, ListEvaluationRequest.EvaluationFilterOption.notEmpty].count {
                return .all
            } else if options.count == 1 { return options.first! } else { return nil }
            }.subscribe(onNext: { [weak self] (option) in
                self?.option.onNext(option)
                self?.page.onNext(1)
                self?.showStatus = .new
            }).disposed(by: self.disposeBag)
    }

}

extension ListReviewVistorUserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let reviews = try? self.reviews.value() {
            let review = reviews[indexPath.row]
            if review.intro.isEmpty && review.review.isEmpty {
                return tableView.frame.width * 0.285
            }
            return tableView.frame.width * 0.42
        }
        return tableView.frame.width * 0.285
    }
}

extension ListReviewVistorUserViewController {
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

