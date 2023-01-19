//
//  ListUserEvaluationViewController.swift
//  gat
//
//  Created by Vũ Kiên on 28/02/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NVActivityIndicatorView
import RealmSwift

class ListUserEvaluationViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var filterButton: UIButton!
    
    override var prefersStatusBarHidden: Bool { return true }
    
    weak var profileViewController: ProfileViewController?
    var height: CGFloat = 0.0
    
    fileprivate var statusShow: SearchState = .new
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate let evaluations: BehaviorSubject<[Review]> = .init(value: [])
    fileprivate let option: BehaviorSubject<ListEvaluationRequest.EvaluationFilterOption?> = .init(value: ListEvaluationRequest.EvaluationFilterOption.all)
    fileprivate var readingStatus = [ReadingStatus]()
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.getData()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.statusShow = .new
        self.page.onNext(1)
        self.searchTextField.attributedPlaceholder = .init(string: Gat.Text.SEARCH_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.filterButton.setTitle(Gat.Text.Filterable.FILTER_TITLE.localized(), for: .normal)
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.getListUserEvaluations()
    }
    
    fileprivate func getListUserEvaluations() {
        self.getReviewFromLocal()
        self.getReviewFromServer()
    }
    
    fileprivate func getReviewFromLocal() {
        Repository<Review, ReviewObject>
            .shared
            .getAll()
            .subscribe(onNext: { [weak self] (reviews) in
                self?.evaluations.onNext(reviews)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getReviewFromServer() {
        self.option.filter { $0 == nil }.map { _ in [Review]() }.subscribe(onNext: self.evaluations.onNext).disposed(by: self.disposeBag)
        Observable<(ListEvaluationRequest.EvaluationFilterOption?, String?, Int, Bool)>
            .combineLatest(
                self.option,
                self.searchTextField.rx.text.asObservable(),
                self.page,
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1, $2, $3) }
            )
            .filter { $0.3 }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .map { ($0.0, $0.1, $0.2) }
            .filter { $0.0 != nil }
            .flatMap {
                ReviewNetworkService
                    .shared
                    .reviews(option: $0, keyword: $1, page: $2)
                    .catchError { (error) -> Observable<[Review]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .flatMap { (reviews) in
                Repository<UserPrivate, UserPrivateObject>
                    .shared
                    .getFirst()
                    .map({ (userPrivate) -> [Review] in
                        reviews.forEach({ (review) in
                            review.user = userPrivate.profile
                        })
                        return reviews
                    })
            }
//            .flatMapLatest({ [weak self] (reviews) -> Observable<[Review]> in
//                return self?.getBookInfoIfNeeded(reviews: reviews) ?? Observable.empty()
//            })
            .do(onNext: { [weak self] (reviews) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false 
                guard let value = try? self?.evaluations.value(), var evaluations = value, let status = self?.statusShow else {
                    return
                }
                switch status {
                case .new:
                    evaluations = reviews
                    break
                case .more:
                    evaluations.append(contentsOf: reviews)
                    break
                }
                self?.evaluations.onNext(evaluations)
            })
            .flatMapLatest { Repository<Review, ReviewObject>.shared.save(objects: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getBookInfoIfNeeded(reviews: [Review]) -> Observable<[Review]> {
        if reviews.isEmpty { return Observable.just(reviews) }
        var list: [Review] = []
        return Observable<Review>
            .from(reviews)
            .flatMapLatest { (review) -> Observable<Review> in
                return Observable<Review>.combineLatest(Observable<Review>.just(review), Repository<BookInfo, BookInfoObject>.shared.getAll(predicateFormat: "editionId = %@", args: [review.book!.editionId]).map { $0.first }, resultSelector: { (review, bookInfo) -> Review in
                    if let book = bookInfo {
                        review.book = book
                    }
                    return review
                })
            }
            .do(onNext: { (review) in
                list.append(review)
            })
            .filter { _ in list.count == reviews.count }
            .map { _ in list }
    }
    
    func deleteReview(review: Review) {
        guard var reviews = try? self.evaluations.value() else {
            return
        }
        review.deleteFlag = true
        Repository<Review, ReviewObject>
            .shared
            .save(object: review)
            .subscribe(onNext: { (_) in
                ReviewBackground.shared.delete()
            })
            .disposed(by: self.disposeBag)
        
        let index = reviews.index(where: { $0.reviewId == review.reviewId })
        if let i = index {
            reviews.remove(at: i)
            self.evaluations.onNext(reviews)
        }
        Repository<UserPrivate, UserPrivateObject>
            .shared
            .getFirst()
            .subscribe(onNext: { [weak self] (userPrivate) in
                self?.profileViewController?.saveUser(articleCount: userPrivate.articleCount - 1)
                self?.profileViewController?.profileTabView.configureReviewBook(number: userPrivate.reviewCount - 1)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK:- UI
    fileprivate func setupUI() {
        self.setupTableView()
    }
    
    func showAlertDelete(review: Review) {
        let okAction = ActionButton(titleLabel: Gat.Text.UserProfile.Review.YES_ALERT_TITLE.localized(), action: { [weak self] in
            self?.deleteReview(review: review)
        })
        let noAction = ActionButton(titleLabel: Gat.Text.UserProfile.Review.NO_ALERT_TITLE.localized(), action: nil)
        self.profileViewController?.showAlert(title: Gat.Text.UserProfile.Review.NOTIFICATION_REMOVE_REVIEW.localized(), message: Gat.Text.UserProfile.Review.REMOVE_MESSAGE.localized(), actions: [okAction, noAction])
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.evaluations
            .bind(to: self.tableView.rx.items(cellIdentifier: "userEvaluationCell", cellType: UserEvaluationTableViewCell.self))
            { [weak self] (index, review, cell) in
                cell.controller = self
                cell.setup(review: review)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func waiting(_ isWaiting: Bool) {
        self.loadingView.isHidden = !isWaiting
        self.view.isUserInteractionEnabled = !isWaiting
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.selectTableView()
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
    
    fileprivate func selectTableView() {
        self.tableView
            .rx
            .modelSelected(Review.self)
            .asDriver()
            .drive(onNext: { [weak self] (review) in
                self?.showReview(review)
            })
            .disposed(by: self.disposeBag)
    }
    
    func showReview(_ review: Review) {
        let storyboard = UIStoryboard(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
        let reviewVC = storyboard.instantiateViewController(withIdentifier: "ReviewViewController") as! ReviewViewController
        reviewVC.review.onNext(review)
        self.profileViewController?.navigationController?.pushViewController(reviewVC, animated: true)
    }
    
    func editReview(_ review: Review) {
        let storyboard = UIStoryboard(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
        let reviewVC = storyboard.instantiateViewController(withIdentifier: "CommentViewController") as! CommentViewController
        reviewVC.review.onNext(review)
        reviewVC.readingStatus.onNext(self.readingStatus.filter { $0.bookInfo?.editionId == review.book?.editionId }.first)
        self.profileViewController?.navigationController?.pushViewController(reviewVC, animated: true)
    }
    
    // MARK: - Navigation
    fileprivate func showFilterOption() {
        let storyboard = UIStoryboard(name: "FilterList", bundle: nil)
        let filterVC = storyboard.instantiateViewController(withIdentifier: FilterListViewController.className) as! FilterListViewController
        filterVC.items.onNext([ListEvaluationRequest.EvaluationFilterOption.empty, ListEvaluationRequest.EvaluationFilterOption.notEmpty])
        filterVC.name.onNext(Gat.Text.Filterable.FILTER_BUTTON.localized())
        if let value = try? self.option.value() {
            if value == .all {
                filterVC.selected.onNext([ListEvaluationRequest.EvaluationFilterOption.empty, ListEvaluationRequest.EvaluationFilterOption.notEmpty])
            } else if value != nil {
                filterVC.selected.onNext([value!])
            } else {
                filterVC.selected.onNext([])
            }
        }
        let sheetController = SheetViewController(controller: filterVC, sizes: [.fixed(347), .fullScreen])
        sheetController.topCornersRadius = 20.0
        self.present(sheetController, animated: true, completion: nil)
        filterVC.acceptSelect()
            .map { $0.compactMap { ListEvaluationRequest.EvaluationFilterOption(rawValue: $0.value) } }
            .map { (option) -> ListEvaluationRequest.EvaluationFilterOption? in
                if option.count == [ListEvaluationRequest.EvaluationFilterOption.empty, ListEvaluationRequest.EvaluationFilterOption.notEmpty].count { return .all } else if option.count == 1 { return option.first } else { return nil }
            }
            .subscribe(onNext: { [weak self] (option) in
                self?.option.onNext(option)
                self?.statusShow = .new
                self?.page.onNext(1)
            })
            .disposed(by: self.disposeBag)
    }
}
extension ListUserEvaluationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let reviews = try? self.evaluations.value() {
            let review = reviews[indexPath.row]
            if review.intro.isEmpty && review.review.isEmpty {
                return tableView.frame.width * 0.285
            } else {
                return tableView.frame.width * 0.42
            }
        } else {
            return tableView.frame.width * 0.285
        }
    }
}

extension ListUserEvaluationViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.height {
            if transition.y < -70 {
                self.statusShow = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if Status.reachable.value {
            let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
            if scrollView.contentOffset.y == 0 {
                if transition.y > 100 {
                    self.statusShow = .new
                    self.page.onNext(1)
                }
            }
        }
//        self.profileViewController?.changeFrame(scrollView: scrollView)
    }
}

extension ListEvaluationRequest.EvaluationFilterOption: Filterable {
    var name: String {
        switch self {
        case .all:
            return "All"
        case .empty:
            return Gat.Text.Filterable.EMPTY_REVIEW.localized()
        case .notEmpty:
            return Gat.Text.Filterable.NOT_EMPTY_REVIEW.localized()
        }
    }
    
    var value: Int {
        return self.rawValue
    }
}
