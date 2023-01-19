//
//  BookDetailContainerController.swift
//  gat
//
//  Created by Vũ Kiên on 15/11/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import ExpandableLabel

class BookDetailContainerController: BaseViewController {
    
    class var segueIdentifier: String {
        return "showDetail"
    }
    
    @IBOutlet weak var tableView: UITableView!
    weak var bookDetailController: BookDetailViewController?
    
    fileprivate var relativeYOffset: CGFloat = 0.0
    
    var height: CGFloat = 0.0
    var book: BehaviorSubject<BookInfo> = .init(value: BookInfo())
    
    private var bookInfo = BookInfo()
    private var userRelation = UserRelation()
    private var isAddReadingCell: Bool = false
    
    var showStatus: SearchState = .new
    let page: BehaviorSubject<Int> = .init(value: 1)
    let review = BehaviorSubject<Review>(value: Review())
    let post = BehaviorRelay<Post?>(value: nil)
    fileprivate let posts = BehaviorRelay<[Post]>(value: [])
    fileprivate var dataSource: DetailCommentDataSource!
    //fileprivate let disposeBag = DisposeBag()
    
    private var viewModelBook: BookViewModel!
    private var getBook = PublishSubject<Int>()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.height = self.bookDetailController!.heightDetailContainerConstraint.multiplier * self.bookDetailController!.view.frame.height
        
        self.bindViewModel()
        
        self.getData()
        self.setupUI()
        self.event()
        
//        self.onAddBookToBoxEvent()
//        self.onAddBookToBoxSuccessEvent()
        self.onAddBookToReadingEvent()
        self.onUpdateReadingEvent()
    }
    
    private func onAddBookToReadingEvent() {
        SwiftEventBus.onMainThread(
            self,
            name: AddBookToReadingEvent.EVENT_NAME
        ) { result in
            print("Received event ")
            self.openReadingProgessPopup()
        }
    }
    
    private func onUpdateReadingEvent() {
        SwiftEventBus.onMainThread(
            self,
            name: UpdateReadingEvent.EVENT_NAME
        ) { result in
            print("Received event ")
            self.updateReadingData()
        }
    }
    
    private func updateReadingData() {
        var items = self.dataSource.items.value
        items.remove(at: 1)
        self.dataSource.items.accept(items.sorted(by: { $0.identity.rawValue < $1.identity.rawValue }))
        self.getBook.onNext(self.bookInfo.editionId)
        self.isAddReadingCell = false
    }
    
    private func openReadingProgessPopup() {
        
        if userRelation.readingStatusId == 1 {
            guard let popupVC = self.getViewControllerFromStorybroad(
                storybroadName: "ReadingProcessView",
                identifier: "ReadingProcessVC"
            ) as? ReadingProcessVC else { return }
            if self.userRelation.readingId > 0 {
                popupVC.editionId = self.bookInfo.editionId
                popupVC.readingId = self.userRelation.readingId
                popupVC.maxSlider = self.userRelation.pageNum != 0 ? self.userRelation.pageNum : self.bookInfo.totalPage
                popupVC.current = self.userRelation.readPage
                popupVC.startDate = self.userRelation.startDate
                popupVC.completeDate = self.userRelation.completeDate
                popupVC.bookTitle = self.bookInfo.title
            } else {
                popupVC.editionId = self.bookInfo.editionId
                popupVC.bookTitle = self.bookInfo.title
                popupVC.maxSlider = self.bookInfo.totalPage
            }
            popupVC.delegate = self
            let navigation = PopupNavigationController(rootViewController: popupVC)
            present(navigation, animated: true, completion: nil)
        } else {
            guard let popupVC = self.getViewControllerFromStorybroad(
                 storybroadName: "ReadingProcessView",
                 identifier: ReviewProcessViewController.className
             ) as? ReviewProcessViewController else { return }
            popupVC.book.accept(self.bookInfo)
            popupVC.delegate = self
            let navigation = PopupNavigationController(rootViewController: popupVC)
            navigation.navigationBar.isHidden = true
            present(navigation, animated: true, completion: nil)
        }
        
        
    }
    
    private func bindViewModel() {
        let useCase = Application.shared.networkUseCaseProvider
        viewModelBook = BookViewModel(useCase: useCase.makeBookUseCase())
        let input = BookViewModel.Input(getBook: getBook)
        let output = viewModelBook.transform(input)
        
        output.book.subscribe(onNext: { book in
            print("Can get Data Mapped Sequence authorName: \(book.authorName)")
            self.getReading(book: book)
        }).disposed(by: disposeBag)
        
        output.error
        .drive(rx.error)
        .disposed(by: disposeBag)
    }
    
    // MARK: - Data
    fileprivate func getData() {
        self.dataSource = DetailCommentDataSource(viewcontroller: self, items: .init(value: [SectionModel(model: .description, items: [""] as [Any])]), disposeBag: self.disposeBag)
        self.book
            .subscribe(onNext: { [weak self] (bookInfo) in
                guard var value = self?.dataSource.items.value else { return }
                value[0] = SectionModel(model: .description, items: [bookInfo.descriptionBook] as [Any])
                self?.dataSource.items.accept(value)
                self?.getBook.onNext(bookInfo.editionId)
                // Set data for BookInfo
                self?.bookInfo.bookId = bookInfo.bookId
                self?.bookInfo.editionId = bookInfo.editionId
                self?.bookInfo.title = bookInfo.title
                self?.bookInfo.totalPage = bookInfo.totalPage
            })
            .disposed(by: self.disposeBag)
        self.getMyReview()
        self.getListReview()
        
    }
    
    fileprivate func getReading(book: Book) {
        // Check if is add reading cell complete
        // then should not add again
        if isAddReadingCell {
            return
        }
        
        var items = self.dataSource.items.value
        
        // Check if userRelation is nil
        // then add default cell is Start reading now
        guard let it = book.userRelation else {
            items.append(.init(model: .reading, items: [0]))
            return
        }
        
        self.userRelation = it
        
        if (!it.isReadingNull) {
            
            var status: ReadingBook.Status = ReadingBook.Status.none
            if it.readingStatusId == 0 {
                status = ReadingBook.Status.finish
            } else {
                status = ReadingBook.Status.reading
            }
            print("Reading status send: \(status)")

            let reading = ReadingBook(
                id: it.readingId,
                book: nil,
                user: nil,
                status: status,
                currentPage: it.readPage,
                lastReadDate: nil,
                followDate: nil,
                startDate: TimeUtils.getDateFromString(it.startDate),
                completedDate: TimeUtils.getDateFromString(it.completeDate),
                editionId: book.editionId,
                pageNum: it.pageNum
            )
            items.append(.init(model: .reading, items: [reading]))
        } else {
            let readingCount = book.summary?.readingCount ?? 0
            items.append(.init(model: .reading, items: [readingCount]))
        }
        
        self.dataSource.items.accept(items.sorted(by: { $0.identity.rawValue < $1.identity.rawValue }))
        self.isAddReadingCell = true
    }
    
    fileprivate func getListReview() {
        self.processReviews()
        self.getListReviewFromServer()
    }
    
    fileprivate func getListReviewFromServer() {
        Observable.combineLatest(self.book, self.page)
            .flatMap { (book, page) -> Observable<[Post]> in
                return PostService.shared.getReview(editionId: book.editionId, pageNum: page, pageSize: 10)
                    .catchErrorJustReturn([])
            }
            .filter { !$0.isEmpty }
            .bind { [weak self] results in
                guard var posts = self?.posts.value, let status = self?.showStatus else { return }
                switch status {
                case .new: posts = results
                case .more: posts.append(contentsOf: results)
                }
                self?.posts.accept(posts)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func processReviews() {
        self.posts.bind { [weak self] (posts) in
            guard var value = self?.dataSource.items.value else { return }
            if let index = value.firstIndex(where: { $0.model == .reviews}) {
                value[index] = SectionModel<Section, Any>(model: .reviews, items: posts)
            } else {
                value.append(SectionModel<Section, Any>(model: .reviews, items: posts))
            }
            self?.dataSource.items.accept(value.sorted(by: { $0.identity.rawValue < $1.identity.rawValue}))
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func getMyReview() {
        Observable<Post>.combineLatest(self.post, self.book.filter { $0.editionId != 0 }, Observable.from(optional: Session.shared.user)) { (post, book, user) -> Post in
            return post != nil ? post! : Post(id: 0, title: "", intro: "", body: "", creator: .init(profile: user.profile!, isFollowing: false), categories: [.init(categoryId: PostCategory.REVIEW_CATEGORY_ID, title: "Review")], postImage: .init(thumbnailId: book.imageId, coverImage: book.imageId, bodyImages: []), editionTags: [book])
        }
            .bind { [weak self] post in
                guard var value = self?.dataSource.items.value else { return }
                if let index = value.firstIndex(where: { $0.model == .myReview}) {
                    value[index] = SectionModel<Section, Any>(model: .myReview, items: [post])
                } else {
                    value.append(SectionModel<Section, Any>(model: .myReview, items: [post]))
                }
                self?.dataSource.items.accept(value.sorted(by: { $0.identity.rawValue < $1.identity.rawValue }))
            }
            .disposed(by: self.disposeBag)
        self.getReviewFromLocal()
        self.getReviewFromServer()
    }
    
    fileprivate func getReviewFromLocal() {
        Observable.combineLatest(self.book.filter { $0.editionId != 0 }, Observable.from(optional: Session.shared.user))
            .flatMap { Repository<Post, PostObject>.shared.getAll(predicateFormat: "SUBQUERY(editionTags, $editionTag, $editionTag.editionId = %d).@count > 0 AND creator.id = %d AND SUBQUERY(categories, $category, $category.categoryId = %d).@count > 0", args: [$0.editionId, $1.id, PostCategory.REVIEW_CATEGORY_ID]) }
            .compactMap { $0.first }
            .bind(onNext: self.post.accept)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getReviewFromServer() {
        let remote = Observable.combineLatest(self.book.filter { $0.editionId != 0 }, Observable.from(optional: Session.shared.user))
            .filter { _ in Session.shared.isAuthenticated }
            .flatMap { (book, user) -> Observable<Post> in
                return PostService.shared.getMyReview(editionId: book.editionId)
                    .catchError { (error) -> Observable<Post> in
                        
                        return .empty()
                    }
            }
            .map { (post) -> Post in
                var p = post
                if let profile = Session.shared.user?.profile {
                    p.creator.profile = profile
                }
                return p
            }
        let rating = self.book.filter { $0.editionId != 0 }
            .filter { _ in Session.shared.isAuthenticated }
            .flatMap { (book) -> Observable<Review> in
            return ReviewNetworkService.shared.review(bookInfo: book)
                .catchError { (error) -> Observable<Review> in
                    HandleError.default.showAlert(with: error)
                    return .empty()
                }
        }
        .share()
        
        let getRating = rating.map { (review) -> Post in
            return .init(id: 0, title: "", intro: "", body: "", creator: .init(profile: review.user!, isFollowing: false), categories: [.init(categoryId: PostCategory.REVIEW_CATEGORY_ID, title: "Review")], postImage: .init(thumbnailId: review.book!.imageId, coverImage: review.book!.imageId, bodyImages: []), editionTags: [review.book!], rating: review.value)
        }
        
        let getArticle = Observable.combineLatest(remote, rating)
            .map { (post, review) -> Post in
                var p = post
                p.rating = review.value
                return p
            }
        Observable.of(getRating, getArticle)
            .merge()
            .do(onNext: self.post.accept)
            .filter { $0.id != 0 }
            .flatMap { Repository<Post, PostObject>.shared.save(object: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.view.layoutIfNeeded()
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.relativeYOffset = self.tableView.contentOffset.y
        self.tableView.estimatedRowHeight = 50
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    // MARK: - Event
    fileprivate func event() {
        self.selectedTableEvent()
        self.updatePost()
    }
    
    fileprivate func selectedTableEvent() {
        self.tableView.rx.itemSelected.asObservable()
            .withLatestFrom(self.dataSource.items.asObservable()) { (indexPath, items) -> Post? in
                guard items[indexPath.section].identity == .reviews else { return nil }
                let item = items[indexPath.section].items[indexPath.row]
                return item as? Post
            }
            .compactMap { $0 }
            .filter { $0.id != 0 }
            .bind { [weak self] post in
                self?.bookDetailController?.performSegue(withIdentifier: PostDetailViewController.segueIdentifier, sender: post)
            }
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.itemSelected.asObservable()
            .withLatestFrom(self.dataSource.items.asObservable()) { (indexPath, items) -> ReadingBook? in
                if items[indexPath.section].model == .reading {
                    return items[indexPath.section].items[indexPath.row] as? ReadingBook
                }
                return nil
        }.compactMap { $0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.openReadingProgessPopup()
            }).disposed(by: self.disposeBag)
        
    }
    
    fileprivate func updatePost() {
        NotificationCenter.default.rx.notification(CompletePublishPostViewController.updatePost)
            .compactMap { $0.object as? Post }
            .do(onNext: { [weak self] (post) in
                guard var posts = self?.posts.value else { return }
                guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
                posts[index] = post
                self?.posts.accept(posts)
            })
            .bind(onNext: self.post.accept)
            .disposed(by: self.disposeBag)
    }
}

extension BookDetailContainerController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = Bundle.main.loadNibNamed(Gat.View.HEADER, owner: self, options: nil)?.first as? HeaderSearch
        header?.backgroundColor = .white
        header?.showView.isHidden = true
        header?.titleLabel.font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.semibold)
        header?.titleLabel.textColor = .black
        header?.titleLabel.text = self.dataSource.items.value[section].model.title
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.05 * self.view.frame.height
    }
}

extension BookDetailContainerController: ExpandableLabelDelegate {
    func willCollapseLabel(_ label: ExpandableLabel) {
        
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        
    }
    
    func willExpandLabel(_ label: ExpandableLabel) {
        self.tableView.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point) {
            if self.tableView.cellForRow(at: indexPath) as? DetailBookTableViewCell != nil {
                self.dataSource.showMoreDescription = false
            }
        }
        
        self.tableView.endUpdates()
    }
}

extension BookDetailContainerController: BookDetailComponents {
    
}

extension BookDetailContainerController {
    enum Section: Int {
        case description = 0
        case reading = 1
        case myReview = 2
        case reviews = 3
        
        var title: String {
            switch self {
            case .description: return Gat.Text.BookDetail.BOOK_DESCRIPTION_TITLE.localized()
            case .myReview: return Gat.Text.BookDetail.MY_REVIEW_TITLE.localized()
            case .reviews: return Gat.Text.BookDetail.REVIEW_BOOK_TITLE.localized()
            default: return ""
            }
        }
    }
    
}

extension BookDetailContainerController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.height {
            if transition.y < -70 {
                self.showStatus = .more
                self.page.onNext(((try? self.page.value()) ?? 0) + 1)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let controller = self.bookDetailController else { return }
        let relativeYOffset = scrollView.contentOffset.y - controller.heightDetailContainerConstraint.multiplier * controller.view.frame.height
        self.height = max(-relativeYOffset, controller.view.frame.height * controller.headerViewHeightConstraint.multiplier) < controller.heightDetailContainerConstraint.multiplier * controller.view.frame.height ? max(-relativeYOffset, controller.view.frame.height * controller.headerViewHeightConstraint.multiplier) : controller.heightDetailContainerConstraint.multiplier * controller.view.frame.height
        controller.view.layoutIfNeeded()
        controller.changeFrameProfileView(height: height)
    }
}

extension BookDetailContainerController: ReadingProcessDelegate {
    
    func readingProcess(readingProcess: ReviewProcessViewController, open post: Post) {
        readingProcess.navigationController?.dismiss(animated: true, completion: nil)
        let step = StepCreateArticleViewController()
        
        let storyboard = UIStoryboard(name: "CreateArticle", bundle: nil)
        let createArticle = storyboard.instantiateViewController(withIdentifier: CreatePostViewController.className) as! CreatePostViewController
        createArticle.presenter = SimpleCreatePostPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimpleCreatePostRouter(viewController: createArticle, provider: step))
        step.add(step: .init(controller: createArticle, direction: .forward))
        step.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(step, animated: true)
        
    }
    
    func update(post: Post) {
        self.post.accept(post)
    }
}
