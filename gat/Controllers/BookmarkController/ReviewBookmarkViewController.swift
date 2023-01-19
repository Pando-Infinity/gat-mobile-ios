import UIKit
import RxSwift

class ReviewBookmarkViewController: UIViewController {
    
    class var segueIdentifier: String { return "showReviewBookmark" }

    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var statusShow: SearchState = .new
    fileprivate let reviews: BehaviorSubject<[Review]> = .init(value: [])
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable<(Int, Bool)>
            .combineLatest(self.page, Status.reachable.asObservable(), resultSelector: { ($0, $1) })
            .filter { $0.1 }
            .map { $0.0 }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap { (page) -> Observable<[Review]> in
                return BookmarkService.shared.listReview(page: page)
                    .catchError({ (error) -> Observable<[Review]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { [weak self] (reviews) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let value = try? self?.reviews.value(), let status = self?.statusShow, var list = value else { return }
                switch status {
                case .new:
                    list = reviews
                case.more:
                    list.append(contentsOf: reviews)
                }
                self?.reviews.onNext(list)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func remove(review: Review) {
        guard var reviews = try? self.reviews.value() else { return }
        reviews.removeAll(where: {$0.reviewId == review.reviewId })
        self.reviews.onNext(reviews)
    }
    
    fileprivate func add(review: Review, index: Int) {
        guard var reviews = try? self.reviews.value() else { return }
        reviews.insert(review, at: index)
        self.reviews.onNext(reviews)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self
        self.reviews.bind(to: self.collectionView.rx.items(cellIdentifier: ReviewBookmarkCollectionViewCell.identifier, cellType: ReviewBookmarkCollectionViewCell.self)) { [weak self] (index, review, cell) in
            cell.index = index
            cell.review.onNext(review)
            cell.remove = self?.remove
            cell.add = self?.add
            cell.perform = self?.performSegue
            cell.show = self?.show
            }.disposed(by: self.disposeBag)
    }
    
    fileprivate func show(vc: UIViewController) {
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.collectionViewEvent()
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(Review.self).subscribe(onNext: { [weak self] (review) in
            let storyboard = UIStoryboard.init(name: "BookDetail", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ReviewViewController.className) as! ReviewViewController
            vc.review.onNext(review)
            vc.delegate = self
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBookDetail" {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == "showVistorProfile" {
            let vc = segue.destination as? UserVistorViewController
            let user = UserPublic()
            user.profile = sender as! Profile
            vc?.userPublic.onNext(user)
        }
    }


}

extension ReviewBookmarkViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let reviews = try? self.reviews.value() else { return .zero }
        return ReviewBookmarkCollectionViewCell.size(review: reviews[indexPath.row], in: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 12.0, left: 12.0, bottom: 12.0, right: 12.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0
    }
}

extension ReviewBookmarkViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.collectionView.contentOffset.y >= self.collectionView.contentSize.height - self.collectionView.frame.height {
            if transition.y < -70 {
                self.statusShow = .more
                self.page.onNext(((try? self.page.value()) ?? 0) + 1)
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
    }
}

extension ReviewBookmarkViewController: NewReviewDelegate {
    func update(review: Review) {
        self.remove(review: review)
    }
    
    func showReview(viewcontroller: UIViewController) {
    }
}
