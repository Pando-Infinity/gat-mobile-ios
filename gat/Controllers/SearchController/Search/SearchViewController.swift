//
//  SearchController.swift
//  gat
//
//  Created by Vũ Kiên on 03/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import HMSegmentedControl

enum SearchState {
    case more
    case new
}

enum ShowState {
    case history
    case search
    case suggest
}

class SearchViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var segmentView: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var showGuideline = false
    let isHiddenTabbar: BehaviorSubject<Bool> = .init(value: false)
    var controllers: [UIViewController] = []
    var previousVC: UIViewController?
    weak var delegate: SearchDelegate?
    fileprivate let items = [Gat.Text.Search.SEARCH_BOOK_TITLE.localized(), Gat.Text.Search.SEARCH_AUTHOR_TITLE.localized(), Gat.Text.Search.SEARCH_USER_TITLE.localized()]
    fileprivate var segmentControl: HMSegmentedControl?
    
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("show: \(self.showGuideline)")
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.segmentControl?.sectionTitles = [Gat.Text.Search.SEARCH_BOOK_TITLE.localized(), Gat.Text.Search.SEARCH_AUTHOR_TITLE.localized(), Gat.Text.Search.SEARCH_USER_TITLE.localized()]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        self.isHiddenTabbar
//            .subscribe(onNext: { [weak self] (status) in
//                self?.tabBarController?.tabBar.isHidden = status
//            })
//            .disposed(by: self.disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setupSegment()
    }
    
    //MARK: - Data
    func addHistory(_ history: History) {
        Repository<History, HistoryObject>
            .shared
            .getAll(predicateFormat: "text = %@ AND type = %@", args: [history.text, history.type.rawValue])
            .map { $0.first }
            .flatMapLatest { (h) -> Observable<History> in
                if h != nil {
                    return Observable<History>.empty()
                } else {
                    return Observable<History>.just(history)
                }
            }
            .flatMapLatest { Repository<History, HistoryObject>.shared.save(object: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    func save(history: History) {
        Repository<History, HistoryObject>
            .shared
            .getFirst(predicateFormat: "text = %@ AND type = %@", args: [history.text, history.type.rawValue])
            .map { (history) -> History in
                history.date = Date()
                return history
            }
            .flatMapLatest { Repository<History, HistoryObject>.shared.save(object: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.performSegue(withIdentifier: Gat.Segue.SHOW_SEARCH_BOOK_IDENTIFIER, sender: nil)
    }
    
    fileprivate func setupSegment() {
        guard self.segmentControl == nil else {
            return
        }
        self.segmentControl = HMSegmentedControl(sectionTitles: self.items)
        self.segmentControl?.frame = self.segmentView.bounds
        self.segmentControl?.layer.masksToBounds = true
        self.segmentControl?.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: TITLE_SEGMENT_COLOR]
        self.segmentControl?.selectionIndicatorLocation = .down
        self.segmentControl?.selectionIndicatorColor = INDICATOR_SEGMENT_SELECT_COLOR
        self.segmentControl?.selectionIndicatorHeight = 3.0
        self.segmentControl?.selectionStyle = .fullWidthStripe
        self.segmentControl?.selectedTitleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.semibold)]
        self.segmentControl?.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        self.segmentView.addSubview(self.segmentControl!)
    }


    //MARK: - Event
    fileprivate func event() {
        self.searchTextFieldEvent()
        let combine = Observable
            .combineLatest(self.delegate!.textSearch, self.delegate!.activeSearch, resultSelector: { ($0, $1) })
            .filter { !$0.isEmpty && $1 }
            .filter { _ in Status.reachable.value }
            .map { $0.0 }
        combine.filter { [weak self] (text) -> Bool in
            guard let index = self?.segmentControl?.selectedSegmentIndex, index == 0 else { return false }
            return true
        }
            .flatMap { SearchNetworkService.shared.historyBook(titles: [$0]).catchError({ (error) -> Observable<()> in
                HandleError.default.showAlert(with: error)
                return Observable.empty()
            }) }
            .subscribe()
            .disposed(by: self.disposeBag)
        combine.filter { [weak self] (text) -> Bool in
            guard let index = self?.segmentControl?.selectedSegmentIndex, index == 1 else { return false }
            return true
        }
            .flatMap { SearchNetworkService.shared.historyAuthor(titles: [$0]).catchErrorJustReturn(()) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func searchTextFieldEvent() {
        Observable<(String, Bool)>
            .combineLatest(self.delegate!.textSearch, self.delegate!.activeSearch, resultSelector: {($0, $1)})
            .filter { !$0.isEmpty && $1 }
            .map { (text, _ ) in text}
            .subscribe(onNext: { [weak self] (text) in
                self?.searchEvent(title: text)
            })
            .disposed(by: self.disposeBag)
    }
    
    
    fileprivate func searchEvent(title: String) {
        switch self.segmentControl!.selectedSegmentIndex {
        case 0:
            let vc = self.controllers.filter({$0.isKind(of: SearchBookViewController.classForCoder())}).first as? SearchBookViewController
            vc?.startSearch(with: title)
            vc?.showGuideline = self.showGuideline
            self.addHistory(History(id: UUID().uuidString, text: title, timeInterval: Date().timeIntervalSince1970, type: .book))
            break
        case 1:
            let vc = self.controllers.filter({$0.isKind(of: SearchAuthorViewController.classForCoder())}).first as? SearchAuthorViewController
            vc?.startSearch(with: title)
            self.addHistory(History(id: UUID().uuidString, text: title, timeInterval: Date().timeIntervalSince1970, type: .author))
            break
        case 2:
            let vc = self.controllers.filter({$0.isKind(of: SearchUserViewController.classForCoder())}).first as? SearchUserViewController
            vc?.startSearch(with: title)
            self.addHistory(History(id: UUID().uuidString, text: title, timeInterval: Date().timeIntervalSince1970, type: .user))
            break
        default:
            break
        }
    }
    
    @objc
    fileprivate func valueChanged(segment: HMSegmentedControl) {
        segment.selectedTitleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.semibold)]
        switch segment.selectedSegmentIndex {
        case 0:
            self.performSegue(withIdentifier: Gat.Segue.SHOW_SEARCH_BOOK_IDENTIFIER, sender: nil)
            break
        case 1:
            self.performSegue(withIdentifier: Gat.Segue.SHOW_SEARCH_AUTHOR_IDENTIFIER, sender: nil)
            break
        case 2:
            self.performSegue(withIdentifier: Gat.Segue.SHOW_SEARCH_USER_IDENTIFIER, sender: nil)
            break
        default:
            break
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_SEARCH_BOOK_IDENTIFIER {
            if let vc = self.controllers.filter({$0.className == segue.destination.className}).first as? SearchBookViewController {
                vc.controller = self
                vc.showGuideline = self.showGuideline
            } else {
                let vc = segue.destination as? SearchBookViewController
                vc?.showGuideline = self.showGuideline
                vc?.controller = self
            }
        } else if segue.identifier == Gat.Segue.SHOW_SEARCH_AUTHOR_IDENTIFIER {
            if let vc = self.controllers.filter({$0.className == segue.destination.className}).first as? SearchAuthorViewController {
                vc.controller = self
            } else {
                let vc = segue.destination as? SearchAuthorViewController
                vc?.controller = self
            }
        } else if segue.identifier == Gat.Segue.SHOW_SEARCH_USER_IDENTIFIER {
            if let vc = self.controllers.filter({$0.className == segue.destination.className}).first as? SearchUserViewController {
                vc.controller = self
            } else {
                let vc = segue.destination as? SearchUserViewController
                vc?.controller = self
            }
        } else if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as! BookDetailViewController
            vc.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        } else if segue.identifier == Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER {
            let vc = segue.destination as? BookStopViewController
            vc?.bookstop.onNext(sender as! Bookstop)
        } else if segue.identifier == "showBookstopOrganization" {
            let vc = segue.destination as? BookstopOriganizationViewController
            print((sender as! Bookstop).id)
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        } else if segue.identifier == AddNewBookViewController.segueIdentifier {
            let vc = segue.destination as? AddNewBookViewController
            vc?.titleBook = (sender as? String) ?? ""
        }
    }
}
