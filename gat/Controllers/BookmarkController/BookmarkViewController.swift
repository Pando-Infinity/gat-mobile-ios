import UIKit
import RxSwift

class BookmarkViewController: UIViewController {
    
    class var segueIdentifier: String { return "showBookmark" }
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bookmarkTabView: BookmarkTabView!
    @IBOutlet weak var containerView: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    var controllers: [UIViewController] = []
    var previousController: UIViewController?
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.performSegue(withIdentifier: BookBookmarkViewController.segueIdentifier, sender: nil)
        self.titleLabel.text = Gat.Text.Bookmark.BOOK_BOOKMARK_TITLE.localized()
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
        self.selectTabEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func selectTabEvent() {
        self.bookmarkTabView.bookTabView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.bookmarkTabView.selectBookTab()
            self?.performSegue(withIdentifier: BookBookmarkViewController.segueIdentifier, sender: nil)
        }).disposed(by: self.disposeBag)
        
        self.bookmarkTabView.reviewTabView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.bookmarkTabView.selectReviewTab()
//            self?.performSegue(withIdentifier: ReviewBookmarkViewController.segueIdentifier, sender: nil)
            self?.performSegue(withIdentifier: "showSavedPost", sender: nil)
        })
        .disposed(by: self.disposeBag)
    }
    

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}

extension BookmarkViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
