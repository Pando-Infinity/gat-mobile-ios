//
//  SharingBookContainer.swift
//  gat
//
//  Created by Vũ Kiên on 26/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RealmSwift

class SharingBookContainer: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var emptyInstanceImageView: UIImageView!
    @IBOutlet weak var emptyInstanceLabel: UILabel!
    
    override var prefersStatusBarHidden: Bool { return true }
    
    weak var profileViewController: ProfileViewController?
    var height: CGFloat = 0.0

    let lineLayer: CAShapeLayer = .init()
    
    fileprivate var statusShow: SearchState = .new
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate let filterOption: BehaviorSubject<[BookInstanceRequest.InstanceFilterOption]> = .init(value: [.sharing, .borrowing, .lost])
    fileprivate var datasources: RxTableViewSectionedReloadDataSource<SectionModel<String, Instance>>!
    fileprivate let items: BehaviorSubject<[SectionModel<String, Instance>]> = .init(value: [])
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.getBookInstance()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.statusShow = .new
        self.page.onNext(1)
        self.searchTextField.attributedPlaceholder = .init(string: Gat.Text.SEARCH_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.filterButton.setTitle(Gat.Text.Filterable.FILTER_TITLE.localized(), for: .normal)
        self.emptyInstanceLabel.text = Gat.Text.UserProfile.BookInstance.ADD_BOOK_MESSAGE.localized()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard try! self.items.value().isEmpty else { return }
        self.drawEmptyInstance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setupTipView()
    }
        
    //MARK: - Data
    fileprivate func getBookInstance() {
        self.getBookInstanceInDatabase()
        self.getBookInstanceFromServer()
    }
    
    fileprivate func getBookInstanceInDatabase() {
        Repository<Instance, InstanceObject>.shared.getAll()
            .map { (instances) -> [SectionModel<String, Instance>] in
                let list = instances.filter { !$0.deleteFlag }
                return [
                    SectionModel<String, Instance>(model: Gat.Text.UserProfile.BookInstance.SHARINGBOOK_TITLE, items: list.filter { $0.sharingStatus == .sharing || $0.sharingStatus == .borrowing }),
                    SectionModel<String, Instance>(model: Gat.Text.UserProfile.BookInstance.LOST_BOOK_TITLE, items: list.filter { $0.sharingStatus == .lost })
                ]
            }
            .subscribe(onNext: { [weak self] (items) in
                self?.items.onNext(items)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getBookInstanceFromServer() {
        self.filterOption.filter { $0.isEmpty }.map { (_) -> [SectionModel<String, Instance>] in
            return [SectionModel<String, Instance>(model: Gat.Text.UserProfile.BookInstance.SHARINGBOOK_TITLE, items: []), SectionModel<String, Instance>(model: Gat.Text.UserProfile.BookInstance.LOST_BOOK_TITLE, items: [])]
        }.subscribe(onNext: self.items.onNext).disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.page, self.searchTextField.rx.text.orEmpty.asObservable().throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance), self.filterOption, Status.reachable.asObservable())
            .filter { $0.3 && Session.shared.isAuthenticated }
            .map { ($0.0, $0.1, $0.2) }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMap {
                InstanceNetworkService.shared
                    .book(status: $2, keyword: $1, page: $0)
                    .catchError { (error) -> Observable<[Instance]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                }
            }
            .flatMapLatest({ (instances) -> Observable<[Instance]> in
                return Observable<[Instance]>
                    .combineLatest(
                        Observable<[Instance]>.just(instances),
                        Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                        resultSelector: { (instances, userPrivate) -> [Instance] in
                            instances.forEach { $0.owner = userPrivate }
                            return instances
                        }
                    )
            })
            .flatMapLatest { [weak self] (instances) in self?.getBookInfoIfNeeded(instances: instances) ?? Observable.empty() }
            .flatMapLatest{ [weak self] (instances) in self?.getBorrowerIfNeeded(instances: instances) ?? Observable.empty() }
            .flatMapLatest { [weak self] (instances) in self?.getRequestIfNeeded(instances: instances) ?? Observable.empty() }
            .do(onNext: { [weak self] (instances) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let value = try? self?.items.value(), var items = value, let status = self?.statusShow else {
                    return
                }
                let sharings = instances.filter { $0.sharingStatus == .sharing || $0.sharingStatus == .borrowing }
                let losts = instances.filter { $0.sharingStatus == .lost }
                switch status {
                case .new:
                    items[0].items = sharings
                    items[1].items = losts
                    break
                case .more:
                    items[0].items.append(contentsOf: sharings)
                    items[1].items.append(contentsOf: losts)
                    break
                }
                self?.items.onNext(items)
            })
            .flatMapLatest { Repository<Instance, InstanceObject>.shared.save(objects: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getBookInfoIfNeeded(instances: [Instance]) -> Observable<[Instance]> {
        if instances.isEmpty { return Observable<[Instance]>.just([]) }
        var list = [Instance]()
        return Observable<Instance>
            .create({ (observer) -> Disposable in
                instances.forEach { observer.onNext($0) }
                return Disposables.create()
            })
            .flatMapLatest({ (instance) -> Observable<Instance> in
                return Observable<Instance>
                    .combineLatest(
                        Observable<Instance>.just(instance),
                        Repository<BookInfo, BookInfoObject>.shared.getAll(predicateFormat: "editionId = %@", args: [instance.book.editionId]).map { $0.first },
                        resultSelector: { (instance, bookInfo) -> Instance in
                            if let book = bookInfo {
                                instance.book = book
                                instance.request?.book = book
                            }
                            return instance
                    }
                )
            })
            .do(onNext: { (instance) in
                list.append(instance)
            })
            .filter { _ in list.count == instances.count }
            .map {_ in list }
    }
    
    fileprivate func getBorrowerIfNeeded(instances: [Instance]) -> Observable<[Instance]> {
        let isEmpty = instances.filter { $0.borrower != nil }.isEmpty
        if isEmpty {
            return Observable<[Instance]>.just(instances)
        }
        let list = instances
        var listBorrower = [Instance]()
        return Observable<Instance>
            .create({ (observer) -> Disposable in
                instances.forEach { observer.onNext($0) }
                return Disposables.create()
            })
            .filter { $0.borrower != nil }
            .flatMapLatest({ (instance) -> Observable<Instance> in
                return Observable<Instance>.combineLatest(Observable<Instance>.just(instance), Repository<Profile, ProfileObject>.shared.getAll(predicateFormat: "id = %@", args: [instance.borrower!.id]).map { $0.first }, resultSelector: { (instance, user) -> Instance in
                    if let borrower = user {
                        instance.borrower = borrower
                    }
                    return instance
                })
            })
            .do(onNext: { (instance) in
                list.filter { $0.id == instance.id }.first?.borrower = instance.borrower
                listBorrower.append(instance)
            })
            .filter { _ in listBorrower.count == instances.filter { $0.borrower != nil}.count }
            .map { _ in list }
    }
    
    func getRequestIfNeeded(instances: [Instance]) -> Observable<[Instance]> {
        let isEmpty = instances.filter { $0.request != nil }.isEmpty
        if isEmpty {
            return Observable<[Instance]>.just(instances)
        }
        let list = instances
        var listRequest = [Instance]()
        return Observable<Instance>
            .create({ (observer) -> Disposable in
                instances.forEach { observer.onNext($0) }
                return Disposables.create()
            })
            .filter { $0.request != nil }
            .flatMapLatest({ (instance) -> Observable<Instance> in
                return Observable<Instance>.combineLatest(Observable<Instance>.just(instance), Repository<BookRequest, BookRequestObject>.shared.getAll(predicateFormat: "recordId = %@", args: [instance.request!.recordId]).map { $0.first }, resultSelector: { (instance, bookRequest) -> Instance in
                    if bookRequest != nil {
                        instance.request = bookRequest
                    }
                    return instance
                })
            })
            .do(onNext: { (instance) in
                list.filter { $0.id == instance.id }.first?.request = instance.request
                listRequest.append(instance)
            })
            .filter { _ in listRequest.count == instances.filter { $0.request != nil}.count }
            .map { _ in list }
    }
    
    fileprivate func delete(instance: Instance, at indexPath: IndexPath) {
        guard var items = try? self.items.value() else {
            return
        }
        instance.deleteFlag = true
        Repository<Instance, InstanceObject>
            .shared
            .save(object: instance)
            .subscribe(onNext: { (_) in
                InstanceBackground.shared.delete()
            })
            .disposed(by: self.disposeBag)
        
        items[indexPath.section].items.remove(at: indexPath.row)
        self.items.onNext(items)
        
        guard instance.sharingStatus == .sharing else {
            return
        }
        Repository<UserPrivate, UserPrivateObject>
            .shared
            .getFirst()
            .subscribe(onNext: { [weak self] (userPrivate) in
                self?.profileViewController?.profileTabView.configureSharingBook(number: userPrivate.instanceCount - 1)
                self?.profileViewController?.saveUser(instanceCount: userPrivate.instanceCount - 1)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
//        self.height = self.profileViewController!.backgroundHeightConstraint.multiplier * self.profileViewController!.view.frame.height
        self.addButton.circleCorner()
        let shared = self.items.map { $0.map { $0.items.isEmpty }.reduce(true, { $0 && $1 }) }.share()
        shared.bind(to: self.tableView.rx.isHidden).disposed(by: self.disposeBag)
        shared.map { !$0 }.bind(to: self.emptyInstanceImageView.rx.isHidden, self.emptyInstanceLabel.rx.isHidden).disposed(by: self.disposeBag)
        shared.map { !$0 }.bind { [weak self] (status) in
            if status {
                self?.lineLayer.removeFromSuperlayer()
            } else {
                self?.drawEmptyInstance()
            }
        }.disposed(by: self.disposeBag)
        self.setupTableView()
    }
    
    fileprivate func setupTipView() {
        guard Repository<UserPrivate, UserPrivateObject>.shared.get() != nil else { return }
        guard let flow = GuidelineService.shared.addBook, !flow.steps[0].completed else { return}
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        let text = String(format: Gat.Text.Guideline.TAP_PLUS_ADD_BOOK.localized(), Gat.Text.Guideline.ADD_BOOK_TITLE.localized())
        let attributedString = NSMutableAttributedString(string: text, attributes: [
          .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
          .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1),
          .paragraphStyle: paragraphStyle
        ])
        attributedString.addAttributes([
          .font: UIFont.systemFont(ofSize: 14.0, weight: .semibold),
          .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        ], range: (text as NSString).range(of: Gat.Text.Guideline.ADD_BOOK_TITLE.localized()))
        
        var preferences = EasyTipView.Preferences()
        preferences.drawing.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        preferences.drawing.backgroundColorTip = .white
        preferences.drawing.shadowColor = #colorLiteral(red: 0.4705882353, green: 0.4705882353, blue: 0.4705882353, alpha: 1)
        preferences.drawing.shadowOpacity = 0.5
        preferences.drawing.arrowPosition = .bottom
        preferences.positioning.maxWidth = UIScreen.main.bounds.width - 32.0
        preferences.drawing.arrowHeight = 20.0
        preferences.animating.dismissOnTap = true
        
        let clipPath = UIBezierPath(arcCenter: self.view.convert(self.addButton.center, to: self.profileViewController!.tabBarController!.view), radius: self.addButton.frame.width / 2.0 + 4.0, startAngle: 0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
        let easyTipView = EasyTipView(attributed: attributedString, clipPath: clipPath, forcus: self.addButton, preferences: preferences, delegate: self)
        easyTipView.show(animated: true, withinSuperview: self.profileViewController!.tabBarController!.view)
    }
    
    fileprivate func drawEmptyInstance() {
        self.lineLayer.removeFromSuperlayer()
        self.lineLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let path = UIBezierPath(arcCenter: .init(x: self.emptyInstanceLabel.center.x, y: self.emptyInstanceLabel.center.y + self.emptyInstanceLabel.frame.height + 8.0), radius: 3.0, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)

        
        path.move(to: .init(x: self.addButton.frame.origin.x - 16.0, y: self.addButton.center.y - 5.0 - 8.0))
        path.addLine(to: .init(x: self.addButton.frame.origin.x - 16.0, y: self.addButton.center.y + 5.0 - 8.0))
        path.addLine(to: .init(x: self.addButton.frame.origin.x + CGFloat(10.0*sqrt(3.0) / 2.0) - 16.0, y: self.addButton.center.y - 8.0))
        path.addLine(to: .init(x: self.addButton.frame.origin.x - 16.0, y: self.addButton.center.y - 5.0 - 8.0))
        
        let pointLayer = CAShapeLayer()
        pointLayer.fillColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        pointLayer.path = path.cgPath
        self.lineLayer.addSublayer(pointLayer)
        
        let linePath = UIBezierPath()
        linePath.move(to: .init(x: self.emptyInstanceLabel.center.x, y: self.emptyInstanceLabel.center.y + self.emptyInstanceLabel.frame.height + 8.0))
        linePath.addCurve(to: .init(x: self.addButton.frame.origin.x - 16.0, y: self.addButton.center.y - 8.0), controlPoint1: .init(x: self.emptyInstanceLabel.center.x, y: self.emptyInstanceLabel.center.y + self.emptyInstanceLabel.frame.height + 8.0), controlPoint2: .init(x: self.emptyInstanceLabel.center.x, y: self.addButton.center.y - 8.0))
        
        let layer = CAShapeLayer()
        
        layer.path = linePath.cgPath
        layer.lineWidth = 2.0
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        self.lineLayer.addSublayer(layer)
        
        self.view.layer.addSublayer(self.lineLayer)
    }
    
    fileprivate func setupTableView() {
        self.addButton.setImage(#imageLiteral(resourceName: "plus1"), for: .normal)
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.registerCell()
        self.setupDataSources()
    }
    
    fileprivate func setupDataSources() {
        self.datasources = RxTableViewSectionedReloadDataSource<SectionModel<String, Instance>>.init(configureCell: { (datasource, tableView, indexPath, instance) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "sharingBookCell", for: indexPath) as! SharingBookTableViewCell
            cell.delegate = self
            cell.setup(instance: instance)
            return cell
        }, canEditRowAtIndexPath: { [weak self] (datasource, indexPath) -> Bool in
            guard let value = try? self?.items.value(), let items = value else {
                return false
            }
            guard items[indexPath.section].items.count > indexPath.row else {
                return false
            }
            return items[indexPath.section].items[indexPath.row].sharingStatus != .borrowing
        })
        self.setupCanEditTableViewCell()
        
        self.items
            .bind(to: self.tableView.rx.items(dataSource: self.datasources))
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func registerCell() {
        let nib = UINib(nibName: "SharingBookTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "sharingBookCell")
    }
    
    fileprivate func setupCanEditTableViewCell() {
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.tableViewEvent()
        self.hideKeyboardEvent()
        self.filterButtonEvent()
        self.addEvent()
    }
    
    fileprivate func addEvent() {
        self.addButton.rx.tap.withLatestFrom(Observable.just(self))
        .subscribe(onNext: { (vc) in
            let storyboard = UIStoryboard(name: "SuggestSearch", bundle: nil)
            let search = storyboard.instantiateViewController(withIdentifier: SearchSuggestionViewController.className) as! SearchSuggestionViewController
            search.firstViewControlerType = .search
            search.onlyViewController = true
            search.hidesBottomBarWhenPushed = true
            search.showGuideline = true
            search.becomSearch.accept(true)
            vc.navigationController?.pushViewController(search, animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func filterButtonEvent() {
        self.filterButton.rx.tap.asObservable().subscribe(onNext: self.showFilterOption).disposed(by: self.disposeBag)
    }
    
    fileprivate func showFilterOption() {
        let storyboard = UIStoryboard(name: "FilterList", bundle: nil)
        let filterVC = storyboard.instantiateViewController(withIdentifier: FilterListViewController.className) as! FilterListViewController
        filterVC.name.onNext(Gat.Text.Filterable.FILTER_BUTTON.localized())
        filterVC.items.onNext(BookInstanceRequest.InstanceFilterOption.allCases)
        if let value = try? self.filterOption.value() {
            filterVC.selected.onNext(value)
        }
        let sheetController = SheetViewController(controller: filterVC, sizes: [.fixed(347), .fullScreen])
        sheetController.topCornersRadius = 20.0
        self.present(sheetController, animated: true, completion: nil)
        filterVC.acceptSelect().subscribe(onNext: { print($0.map { $0.value }) }).disposed(by: self.disposeBag)
        filterVC.acceptSelect().map { $0.compactMap { BookInstanceRequest.InstanceFilterOption(rawValue: $0.value) } }.subscribe(onNext: { [weak self] (option) in
            self?.filterOption.onNext(option)
            self?.page.onNext(1)
            self?.statusShow = .new
        }).disposed(by: self.disposeBag)
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
    
    fileprivate func tableViewEvent() {
        self.deleteTableViewCell()
        self.selectTableViewCell()
    }
    
    fileprivate func deleteTableViewCell() {
        self.tableView.rx.itemDeleted
            .flatMapLatest { [weak self] (indexPath) -> Observable<(Instance, IndexPath)> in
                guard let value = try? self?.items.value(), let instances = value else {
                    return Observable.empty()
                }
                return Observable<(Instance, IndexPath)>.just((instances[indexPath.section].items[indexPath.row], indexPath))
            }
            .subscribe(onNext: { [weak self] (instance, indexPath) in
                let okAction = ActionButton(titleLabel: Gat.Text.UserProfile.BookInstance.YES_ALERT_TITLE.localized(), action: { [weak self] in
                    self?.delete(instance: instance, at: indexPath)
                })
                let noAction = ActionButton(titleLabel: Gat.Text.UserProfile.BookInstance.NO_ALERT_TITLE.localized(), action: nil)
                self?.profileViewController?.showAlert(title: Gat.Text.UserProfile.BookInstance.REMOVE_ALERT_TITLE.localized(), message: String(format: Gat.Text.UserProfile.BookInstance.REMOVE_MESSAGE.localized(), instance.book.title), actions: [okAction, noAction])
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func selectTableViewCell() {
        self.tableView
            .rx
            .itemSelected
            .asObservable()
            .flatMapLatest { [weak self] (indexPath) -> Observable<Instance> in
                guard let value = try? self?.items.value(), let instances = value else {
                    return Observable.empty()
                }
                return Observable<Instance>.just(instances[indexPath.section].items[indexPath.row])
            }
            .filter { $0.sharingStatus == .borrowing && $0.request != nil }
            .subscribe(onNext: { [weak self] (instance) in
                self?.profileViewController?.performSegue(withIdentifier: Gat.Segue.SHOW_REQUEST_DETAIL_O_IDENTIFIER, sender: instance.request)
            })
            .disposed(by: self.disposeBag)
    }
}

extension SharingBookContainer: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.width * 4.0 / 15.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let items = try? self.items.value() else {
            return UIView()
        }
        if items[section].items.isEmpty {
            return UIView()
        } else {
            let header = Bundle.main.loadNibNamed("ProfileHeader", owner: self, options: nil)?.first as? ProfileHeaderView
            header?.titleLabel.text = items[section].model.localized()
            return header
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.08 * tableView.frame.width
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if let items = try? self.items.value(), items[indexPath.section].items[indexPath.row].sharingStatus != .borrowing {
            return .delete
        }
        return .none
    }
}

extension SharingBookContainer: SharingBookCellDelegate {
    func changeScene(identifier: String, sender: Any?) {
        self.profileViewController?.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension SharingBookContainer {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.height {
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

extension BookInstanceRequest.InstanceFilterOption: Filterable {
    var name: String {
        switch self {
        case .sharing: return Gat.Text.Filterable.AVAILABLE_BOOK.localized()
        case .borrowing: return Gat.Text.Filterable.NOT_AVAILABLE_BOOK.localized()
        case .lost: return Gat.Text.Filterable.LOST_BOOK.localized()
        }
    }
    
    var value: Int { return self.rawValue }
}

extension SharingBookContainer: EasyTipViewDelegate {
    func easyTipViewDidDismiss(_ tipView: EasyTipView, forcus: Bool) {
        let flow = GuidelineService.shared.addBook!
        let step = flow.steps[0]
        GuidelineService.shared.complete(step: step)
        guard forcus else { return }
        let storyboard = UIStoryboard(name: "SuggestSearch", bundle: nil)
        let search = storyboard.instantiateViewController(withIdentifier: SearchSuggestionViewController.className) as! SearchSuggestionViewController
        search.firstViewControlerType = .search
        search.onlyViewController = true
        search.hidesBottomBarWhenPushed = true
        search.showGuideline = true
        search.becomSearch.accept(true)
        self.navigationController?.pushViewController(search, animated: true)
    }
    
    
}
