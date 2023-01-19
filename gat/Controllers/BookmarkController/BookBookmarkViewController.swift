import UIKit
import RxSwift

protocol RemoveBookBookmark: class {
    func removeBookmark(book: BookInfo)
}

class BookBookmarkViewController: UIViewController {
    
    class var segueIdentifier: String { return "showBookBookmark" }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var statusShow: SearchState = .new
    fileprivate let books: BehaviorSubject<[BookInfo]> = .init(value: [])
    
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
            .flatMap { (page) -> Observable<[BookInfo]> in
                return BookmarkService.shared.listBook(page: page)
                    .catchError({ (error) -> Observable<[BookInfo]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
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
    
    internal func remove(book: BookInfo) {
        guard var books = try? self.books.value() else { return }
        books.removeAll(where: {$0.editionId == book.editionId })
        self.books.onNext(books)
    }
    
    fileprivate func add(book: BookInfo, index: Int) {
        guard var books = try? self.books.value() else { return }
        books.insert(book, at: index)
        self.books.onNext(books)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self
        self.books.bind(to: self.collectionView.rx.items(cellIdentifier: BookBookmarkCollectionViewCell.identifier, cellType: BookBookmarkCollectionViewCell.self)) { [weak self] (index, book, cell) in
            cell.index = index
            cell.book.onNext(book)
            cell.remove = self?.remove
            cell.add = self?.add
        }.disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.collectionViewEvent()
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(BookInfo.self).subscribe(onNext: { [weak self] (book) in
            self?.performSegue(withIdentifier: "showBookDetail", sender: book)
        }).disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBookDetail" {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
            vc?.delegate = self 
        }
    }

}

extension BookBookmarkViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let books = try? self.books.value() else { return .zero }
        return BookBookmarkCollectionViewCell.size(book: books[indexPath.row],in: collectionView)
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

extension BookBookmarkViewController {
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

extension BookBookmarkViewController: RemoveBookBookmark {
    func removeBookmark(book: BookInfo) {
        self.remove(book: book)
    }

}
