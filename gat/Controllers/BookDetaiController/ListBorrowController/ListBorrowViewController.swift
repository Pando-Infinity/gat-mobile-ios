//
//  ListBorrowViewController.swift
//  gat
//
//  Created by Vũ Kiên on 13/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation

class ListBorrowViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loading: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleSortOptionLabel: UILabel!
    @IBOutlet weak var sortOptionView: UIView!
    
    fileprivate var easyTip: EasyTipView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    let bookInfo: BehaviorSubject<BookInfo> = .init(value: BookInfo())
    fileprivate var userSharingBooks = [UserSharingBook]()
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var showStatus: SearchState = .new
    fileprivate let sortOption: BehaviorSubject<SortOption> = .init(value: .activeTime)
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.getTotal()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    //MARK: - Data
    fileprivate func getData() {
        Observable<(BookInfo, UserPrivate?, CLLocationCoordinate2D, SortOption, Int, Bool)>
            .combineLatest(
                self.bookInfo,
                self.getUserPrivate(),
                self.getLocation(),
                self.sortOption,
                self.page,
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1, $2, $3, $4, $5) }
            )
            .filter { (_, _, _, _, _, status) in status }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .map { (bookInfo, userPrivate, location, option , page, _) -> (BookInfo, UserPrivate?, CLLocationCoordinate2D?, SortOption, Int) in
                return (bookInfo, userPrivate, location != CLLocationCoordinate2D() ? location : nil, option, page)
            }
            .flatMapLatest {
                BookNetworkService
                    .shared
                    .listSharing(book: $0, user: $1?.profile, location: $2, activeFlag: false, sortBy: $3, page: $4)
                    .catchError { (error) -> Observable<[UserSharingBook]> in
                        HandleError.default.showAlert(with: error)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return Observable.empty()
                    }
            }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .subscribe(onNext: { [weak self] (list) in
                guard let status = self?.showStatus else {
                    return
                }
                switch status {
                case .new:
                    self?.userSharingBooks = list
                    break
                case .more:
                    self?.userSharingBooks.append(contentsOf: list)
                    break
                }
                self?.tableView.reloadData()
                self?.setupTipView()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getLocation() -> Observable<CLLocationCoordinate2D> {
        return LocationManager
            .manager
            .location
            .catchErrorJustReturn(CLLocationCoordinate2D())
    }
    
    fileprivate func getTotal() {
        Observable<(CLLocationCoordinate2D, BookInfo, Profile?, Bool)>
            .combineLatest(
                self.getLocation(),
                self.bookInfo,
                self.getUserPrivate().map { $0?.profile },
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1, $2, $3 ) }
            )
            .filter { (_, bookInfo, _, status) in status && bookInfo.editionId != 0 }
            .map { (location, bookInfo, user, _) in (location != CLLocationCoordinate2D() ? location : nil, bookInfo, user) }
            .flatMap {
                BookNetworkService
                    .shared
                    .totalSharing(book: $1, user: $2, location: $0)
                    .catchErrorJustReturn(0)
            }
            .map { (total) in
                if total == 0 {
                    return Gat.Text.ListSharingBook.BOOKSELF_TITLE.localized()
                } else {
                    return Gat.Text.ListSharingBook.BOOKSELF_TITLE.localized() + " (\(total))"
                }
            }
            .subscribe(self.titleLabel.rx.text)
            .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func getUserPrivate() -> Observable<UserPrivate?> {
        return Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first }
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = Gat.Text.ListSharingBook.BOOKSELF_TITLE.localized()
        self.setupTableView()
    }
    
    fileprivate func setupTipView() {
        guard !self.userSharingBooks.isEmpty, Repository<UserPrivate, UserPrivateObject>.shared.get() != nil else { return }
        guard let borrow = GuidelineService.shared.borrowBook, !borrow.complete else { return }
        self.configTipView()
    }
    
    fileprivate func configTipView() {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        preferences.drawing.backgroundColorTip = .white
        preferences.drawing.shadowColor = #colorLiteral(red: 0.4705882353, green: 0.4705882353, blue: 0.4705882353, alpha: 1)
        preferences.drawing.shadowOpacity = 0.5
        preferences.drawing.arrowPosition = .top
        preferences.positioning.maxWidth = UIScreen.main.bounds.width - 32.0
        preferences.drawing.arrowHeight = 16.0
        preferences.positioning.bubbleHInset = 0
        preferences.positioning.bubbleVInset = 0
        preferences.positioning.contentHInset = 0
        preferences.positioning.contentVInset = 0
        preferences.animating.dismissOnTap = true
        
        let width = self.tableView.frame.width
        let upper = self.tableView.visibleCells.count >= 3 ? 3 : self.tableView.visibleCells.count
        let height = self.tableView.visibleCells[0..<upper].map { $0.frame.height }.reduce(0.0, +)
        let rectOfCellInTableView = self.tableView.rectForRow(at: .init(row: 0, section: 0))
        let rectOfCellInSuperview = self.tableView.convert(rectOfCellInTableView, to: self.view)
        
        let clipPath = UIBezierPath(rect: .init(origin: rectOfCellInSuperview.origin, size: .init(width: width, height: height)))
        let easyTip = EasyTipView(view: self.configAlertTip(), forcus: self.tableView.visibleCells[upper - 1], clipPath: clipPath, preferences: preferences, delegate: self)
        easyTip.show(withinSuperview: self.view)
        self.easyTip = easyTip
    }
    
    fileprivate func configAlertTip() -> UIView {
        guard let book = try? self.bookInfo.value() else { return .init() }
        let alert = UIView(frame: .init(origin: .zero, size: .init(width: self.tableView.frame.width - 32.0, height: 100.0)))
        let label = UILabel()
        label.numberOfLines = 0
        label.frame.origin = .init(x: alert.bounds.origin.x + 8.0, y: alert.bounds.origin.y + 16.0)
        alert.addSubview(label)
        
        label.frame.size.width = alert.frame.width - 16.0
        label.preferredMaxLayoutWidth = alert.frame.width - 16.0
        
        let text = String(format: Gat.Text.Guideline.LENDING.localized(), book.title)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center
        let attributedString = NSMutableAttributedString(string: text, attributes: [
          .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
          .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1),
          .paragraphStyle: paragraphStyle
        ])
        attributedString.addAttributes([
          .font: UIFont.systemFont(ofSize: 14.0, weight: .semibold),
          .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        ], range: (text as NSString).range(of: book.title))
        label.attributedText = attributedString
        
        let sizeLabel = label.sizeThatFits(.init(width: label.frame.size.width, height: .infinity))
        label.frame.size.height = sizeLabel.height
        
        let seperateView = UIView(frame: .init(origin: .init(x: 0.0, y: label.frame.origin.y + sizeLabel.height + 16.0), size: .init(width: alert.frame.width, height: 1.0)))
        seperateView.backgroundColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        
        alert.addSubview(seperateView)
        
        let button = UIButton(frame: .init(x: 0.0, y: seperateView.frame.origin.y + seperateView.frame.height, width: alert.frame.width, height: 40.0))
        button.setAttributedTitle(.init(string: Gat.Text.Guideline.COMPLETE.localized(), attributes: [.font: UIFont.systemFont(ofSize: 16.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)]), for: .normal)
        alert.addSubview(button)
        alert.frame.size.height = button.frame.origin.y + button.frame.height
        
        button.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.easyTip.dismiss(focus: true)
            GuidelineService.shared.complete(flow: GuidelineService.shared.borrowBook!)
        }).disposed(by: self.disposeBag)
        
        return alert
    }
    
    fileprivate func setupTableView() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
    }
    
    fileprivate func setupSortOptionLabel(option: SortOption) {
        let text = (Gat.Text.ListSharingBook.SORT_BY_TITLE.localized() + ": " + option.toString()).uppercased()
        let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text.uppercased(), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]))
        attributes.addAttributes([NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON], range: NSRange(location: text.count - option.toString().count, length: option.toString().count))
        self.titleSortOptionLabel.attributedText = attributes
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.sortOptionEvent()
        self.backEvent()
        self.showSortOption()
    }
    
    fileprivate func showSortOption() {
        self.sortOptionView
            .rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.performSegue(withIdentifier: "showSortOption", sender: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func sortOptionEvent() {
        self.sortOption
            .bind { [weak self] (option) in
                self?.setupSortOptionLabel(option: option)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: self.disposeBag)
    }
    
    @IBAction func backListSharing(_ segue: UIStoryboardSegue) {
        if segue.identifier == "backListSharing" {
            let vc = segue.source as! SortByListSharingBookViewController
            self.showStatus = .new
            self.sortOption.onNext(vc.option)
            self.page.onNext(1)
        }
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER  {
            let vc = segue.destination as! UserVistorViewController
            vc.userPublic.onNext(sender as! UserPublic)
        } else if segue.identifier == Gat.Segue.SHOW_REQUEST_DETAIL_S_IDENTIFIER {
            let vc = segue.destination as! RequestBorrowerViewController
            vc.bookRequest.onNext(sender as! BookRequest)
        } else if segue.identifier == Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER {
            let vc = segue.destination as? BookStopViewController
            vc?.bookstop.onNext(sender as! Bookstop)
        } else if segue.identifier == Gat.Segue.SHOW_REQUEST_DETAIL_BORROWER_INDETIFIER {
            let vc = segue.destination as? RequestDetailBorrowerViewController
            vc?.userSharingBook.onNext(sender as! UserSharingBook)
        } else if segue.identifier == "showSortOption" {
            let vc = segue.destination as? SortByListSharingBookViewController
            do {
                vc?.option = try self.sortOption.value()
            } catch {
                
            }
        } else if segue.identifier == "showBookstopOrganization" {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        }
    }
}

extension ListBorrowViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userSharingBooks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let userSharingBook = self.userSharingBooks[indexPath.row]
        if userSharingBook.profile.userTypeFlag == .normal {
            if userSharingBook.availableStatus && userSharingBook.request == nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_BORROW_1, for: indexPath) as! UserBorrowTableViewCell1
                cell.viewcontroller = self
                cell.setup(userSharingBook: userSharingBook)
                return cell
            } else if !userSharingBook.availableStatus && userSharingBook.request == nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_BORROW_2, for: indexPath) as! UserBorrowTableViewCell2
                cell.viewcontroller = self
                cell.setup(userSharingBook: userSharingBook)
                return cell
            } else if userSharingBook.availableStatus && userSharingBook.request != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_BORROW_3, for: indexPath) as! UserBorrowTableViewCell3
                cell.viewcontroller = self
                cell.setup(userSharingBook: userSharingBook)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_BORROW_4, for: indexPath) as! UserBorrowTableViewCell4
                cell.viewcontroller = self
                cell.setup(userSharingBook: userSharingBook)
                return cell
            }
        } else if userSharingBook.profile.userTypeFlag == .bookstop {
            let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_BORROW_5, for: indexPath) as! UserBorrowTableViewCell5
            cell.viewcontroller = self
            cell.setup(userSharingBook: userSharingBook)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_BORROW_6, for: indexPath) as! UserBorrowTableViewCell6
            cell.controller = self
            cell.setup(userSharingBook: userSharingBook)
            return cell
        }
    }
}

extension ListBorrowViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let userSharingStatus = self.userSharingBooks[indexPath.row]
        if userSharingStatus.profile.userTypeFlag == .normal {
            if userSharingStatus.availableStatus && userSharingStatus.request == nil {
                return 0.1 * tableView.frame.height
            } else if !userSharingStatus.availableStatus && userSharingStatus.request == nil {
                return 0.13 * tableView.frame.height
            } else if userSharingStatus.availableStatus && userSharingStatus.request != nil {
                return 0.1 * tableView.frame.height
            } else {
                return 0.13 * tableView.frame.height
            }
        } else {
            return 0.12 * tableView.frame.height
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userSharingBook = self.userSharingBooks[indexPath.row]
        guard userSharingBook.request != nil else {
            return
        }
        self.performSegue(withIdentifier: Gat.Segue.SHOW_REQUEST_DETAIL_S_IDENTIFIER, sender: userSharingBook.request)
    }
}

extension ListBorrowViewController {
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
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if scrollView.contentOffset.y == 0 {
            if transition.y > 100 {
                self.showStatus = .new
                self.page.onNext(1)
            }
        }
    }
}

extension ListBorrowViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension ListBorrowViewController: EasyTipViewDelegate {
    func easyTipViewDidDismiss(_ tipView: EasyTipView, forcus: Bool) {
        GuidelineService.shared.complete(flow: GuidelineService.shared.addBook!)
    }
}
