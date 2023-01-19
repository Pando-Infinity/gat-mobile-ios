import UIKit
import RxSwift

class BookUpdateViewController: UIViewController {
    
    class var segueIdentifier: String { return "showBookWaiting" }
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addNewButton: UIButton!
    
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var statusShow: SearchState = .new
    fileprivate let books: BehaviorSubject<[BookUpdate]> = .init(value: [])
    fileprivate let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.data()
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.page.onNext(1)
        self.statusShow = .new
    }
    
    // MARK: - Data
    fileprivate func data() {
        Observable<(Int, Bool)>
            .combineLatest(self.page, Status.reachable.asObservable(), resultSelector: { ($0, $1) })
            .filter { $0.1 }
            .map { $0.0 }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap { (page) -> Observable<[BookUpdate]> in
                return BookUpdateSerivce.shared.list(page: page).catchError({ (error) -> Observable<[BookUpdate]> in
                    HandleError.default.showAlert(with: error)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    return Observable.empty()
                })
            }
            .subscribe(onNext: { [weak self] (books) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let value = try? self?.books.value(), let status = self?.statusShow, var list = value else { return }
                switch status {
                case .new:
                    list = books
                case.more:
                    list.append(contentsOf: books)
                }
                self?.books.onNext(list)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = Gat.Text.BookUpdate.BOOK_UPDATE_TITLE.localized()
        self.addNewButton.setTitle(Gat.Text.AddNewBook.ADD_NEW_BOOK_TITLE.localized(), for: .normal)
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self
        self.books.bind(to: self.collectionView.rx.items(cellIdentifier: BookUpdateCollectionViewCell.identifier, cellType: BookUpdateCollectionViewCell.self)) { (index, book, cell) in
            cell.book.onNext(book)
        }.disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
        self.addNewEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }

    fileprivate func addNewEvent() {
        self.addNewButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.performSegue(withIdentifier: AddNewBookViewController.segueIdentifier, sender: nil)
        }).disposed(by: self.disposeBag)
    }
}

extension BookUpdateViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let books = try? self.books.value() else { return .zero }
        return BookUpdateCollectionViewCell.size(book: books[indexPath.row],in: collectionView)
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

extension BookUpdateViewController {
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

extension BookUpdateViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
