//
//  NotificationViewController.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import CoreLocation

class NotificationViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate let items: BehaviorSubject<[SectionModel<String, UserNotification>]> = .init(value: [])
    fileprivate let notifications: BehaviorSubject<[UserNotification]> = .init(value: [])
    fileprivate var page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var showStatus: SearchState = .new
    fileprivate let disposeBag = DisposeBag()
    

    //MARK: - View State
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupUI()
        self.event()
        self.getData()
        if Session.shared.isAuthenticated {
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                var items = try! self.notifications.value()
                let notification = UserNotification()
                notification.notificationType = -1
                notification.beginTime = Date()
                notification.user = .init()
                notification.user?.id = -1
                items.insert(notification, at: 0)
                self.notifications.onNext(items)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !Session.shared.isAuthenticated {
            HandleError.default.loginAlert(action: { [weak self] in
                self?.tabBarController?.selectedViewController = self?.tabBarController?.viewControllers?.first
            })
        }
        self.titleLabel.text = Gat.Text.Notification.NOTIFICATION_TITLE.localized()
        self.getDataFromLocal()
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.processNotification()
        self.getDataFromLocal()
        self.getDataFromServer()
    }
    
    fileprivate func getDataFromServer() {
        Observable.combineLatest(self.page, Status.reachable.asObservable())
            .do(onNext: { (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { $0.1 && Session.shared.isAuthenticated }
            .map { $0.0 }
            .flatMapLatest {
                NotificationNetworkService
                    .shared
                    .list(page: $0)
                    .catchError({ (error) -> Observable<[UserNotification]> in
                        HandleError.default.showAlert(with: error)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return Observable.empty()
                    })
            }
            .do(onNext: { [weak self] (userNotifications) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.tabBarController?.tabBar.items?[3].badgeValue = nil
                UIApplication.shared.applicationIconBadgeNumber = 0
                guard let value = try? self?.notifications.value(), var notifications = value, let status = self?.showStatus else {
                    return
                }
                switch status {
                case .new:
                    notifications = userNotifications
                    break
                case .more:
                    notifications.append(contentsOf: userNotifications)
                    break
                }
                self?.notifications.onNext(notifications)
            })
            .flatMapLatest { Repository<UserNotification, UserNotificationObject>.shared.save(objects: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func save(user: Profile) {
        Repository<Profile, ProfileObject>.shared.save(object: user).subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func getDataFromLocal() {
        Repository<UserNotification, UserNotificationObject>
            .shared
            .getAll(sortBy: "beginTime", ascending: false)
            .subscribe(onNext: { [weak self] (userNotifications) in
                self?.notifications.onNext(userNotifications)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func processNotification() {
        self.notifications
            .filter { !$0.isEmpty }
            .map({ (notifications) -> [SectionModel<String, UserNotification>] in
                var results = [SectionModel<String, UserNotification>]()
                notifications.forEach({ (notification) in
                    let day = AppConfig.sharedConfig.stringFormatter(from: notification.beginTime, format: LanguageHelper.language == .japanese ? "yyyy MMM d E" : "E, d MMM yyyy")
                    if results.isEmpty {
                        let sectionModel = SectionModel<String, UserNotification>(model: day, items: [notification])
                        results.append(sectionModel)
                    } else {
                        if day == results.last!.model {
                            results[results.count - 1].items.append(notification)
                        } else {
                            let sectionModel = SectionModel<String, UserNotification>(model: day, items: [notification])
                            results.append(sectionModel)
                        }
                    }
                })
                return results
            })
            .subscribe(onNext: { [weak self] (items) in
                self?.items.onNext(items)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = Gat.Text.Notification.NOTIFICATION_TITLE.localized()
        self.setupTableView()
    }

    
    fileprivate func setupTableView() {
//        let datasources = NotificationDataSource()
        let datasource = RxTableViewSectionedReloadDataSource<SectionModel<String, UserNotification>>.init(configureCell: { (datasource, tableView, indexPath, notification) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_NOTIFICATION, for: indexPath) as! NotificationTableViewCell
            cell.setup(notification: notification)
            return cell
        })
        self.tableView.delegate = self
        self.items
            .bind(to: self.tableView.rx.items(dataSource: datasource))
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.tableViewSelectedEvent()
    }
    
    fileprivate func tableViewSelectedEvent() {
        self.tableView
            .rx
            .itemSelected
            .asObservable()
            .flatMapLatest { [weak self] (indexPath) -> Observable<UserNotification> in
                guard let value = try? self?.items.value(), let items = value else {
                    return Observable.empty()
                }
                return Observable<UserNotification>.just(items[indexPath.section].items[indexPath.row])
            }
            .subscribe(onNext: { [weak self] (notification) in
                switch notification.notificationType {
                case -1:
                    let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: WalletViewController.className)
                    self?.navigationController?.pushViewController(vc, animated: true)
                    break 
                case 0:
                    self?.performSegue(withIdentifier: Gat.Segue.SHOW_GROUP_MESSAGES_IDENTIFIER, sender: nil)
                    break
                case 1, 12, 122, 123:
                    let storyboard = UIStoryboard(name: Gat.Storyboard.MESSAGE, bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: Gat.View.MessageViewController) as! MessageViewController
                    guard let friend = notification.user, let userPrivate = Repository<UserPrivate, UserPrivateObject>.shared.get() else { break }
                    if Repository<Profile, ProfileObject>.shared.get(predicateFormat: "id = %@", args: [friend.id]) == nil {
                        self?.save(user: friend)
                    }
                    let group = GroupMessage()
                    group.groupId = userPrivate.id > friend.id ? "\(friend.id):\(userPrivate.id)" : "\(userPrivate.id):\(friend.id)"
                    group.users.append(friend)
                    vc.group.onNext(group)
                    self?.navigationController?.pushViewController(vc, animated: true)
                    break
                case 10, 19, 121:
                    self?.performSegue(withIdentifier: Gat.Segue.SHOW_REQUEST_DETAIL_O_IDENTIFIER, sender: notification)
                    break
                case 11, 13...16:
                    self?.performSegue(withIdentifier: Gat.Segue.SHOW_REQUEST_DETAIL_S_IDENTIFIER, sender: notification)
                    break
                case 17, 18, 120:
                    let personStoryboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                    let vc = personStoryboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                    vc.isShowButton.onNext(true)
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                    break
                case 20, 21:
                    let storyboard = UIStoryboard(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: ListBorrowViewController.className) as! ListBorrowViewController
                    let bookInfo = BookInfo()
                    bookInfo.editionId = notification.targetId
                    vc.bookInfo.onNext(bookInfo)
                    self?.navigationController?.pushViewController(vc, animated: true)
                    break 
                case 200, 203:
                    let storyboard = UIStoryboard(name: Gat.Storyboard.BARCODE, bundle: nil)
                    let barcodeVC = storyboard.instantiateViewController(withIdentifier: Gat.View.BARCODE_CONTROLLER) as! BarcodeScannerController
                    self?.navigationController?.pushViewController(barcodeVC, animated: true)
                    break
                case 201:
                    self?.performSegue(withIdentifier: Gat.Segue.SHOW_MAP_LOCATION_IDENTIFIER, sender: nil)
                    break
                case 202:
                    self?.performSegue(withIdentifier: Gat.Segue.SHOW_FAVOURITE_CATEGORY_IDENTIFIER, sender: nil)
                    break
                case 301:
                    self?.performSegue(withIdentifier: Gat.Segue.NEARBY_USER_IDENTIFIER, sender: nil)
                    break
                case 500:
                    let user = UserPublic()
                    user.profile = notification.user ?? Profile()
                    self?.performSegue(withIdentifier: Gat.Segue.openVisitorPage, sender: user)
                case 502:
                    self?.performSegue(withIdentifier: FollowViewController.segueIdentifier, sender: nil)
                case 600:
                    let book = BookInfo()
                    book.editionId = notification.targetId
                    book.title = notification.referName
                    self?.performSegue(withIdentifier: "showBookDetail", sender: book)
                case 800, 801, 802, 803:
                    self?.performSegue(withIdentifier: "showChallengeDetail", sender: notification.referId)
                case 900,901,904,905,908,910:
                    let post = Post.init(id: notification.referId, title: "", intro: "", body: "", creator: .init(profile: .init(), isFollowing: false), categories: .init(), postImage: .init(), editionTags: [], userTags: [], hashtags: [], state: .published, date: .init(), userReaction: .init(), summary: .init(), rating: 0.0, saving: false)
                    self?.performSegue(withIdentifier: PostDetailViewController.segueIdentifier, sender: post)
                case 902,903,906,907,909:
                    let post = Post.init(id: notification.targetId, title: "", intro: "", body: "", creator: .init(profile: .init(), isFollowing: false), categories: .init(), postImage: .init(), editionTags: [], userTags: [], hashtags: [], state: .published, date: .init(), userReaction: .init(), summary: .init(), rating: 0.0, saving: false)
                    self?.performSegue(withIdentifier: PostDetailViewController.segueIdentifier, sender: post)
                default:
                    break
                }

            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_REQUEST_DETAIL_O_IDENTIFIER {
            let vc = segue.destination as? RequestOwnerViewController
            let notification = sender as! UserNotification
            Repository<BookRequest, BookRequestObject>
                .shared
                .getAll(predicateFormat: "recordId = %@", args: [notification.referId])
                .map { $0.first }
                .subscribe(onNext: { (bookRequest) in
                    var bookRequest = bookRequest
                    if bookRequest == nil {
                        bookRequest = BookRequest()
                        bookRequest?.recordId = notification.referId
                    }
                    vc?.bookRequest.onNext(bookRequest!)
                })
                .disposed(by: self.disposeBag)
        } else if segue.identifier == Gat.Segue.SHOW_REQUEST_DETAIL_S_IDENTIFIER {
            let vc = segue.destination as? RequestBorrowerViewController
            let notification = sender as! UserNotification
            Repository<BookRequest, BookRequestObject>
                .shared
                .getAll(predicateFormat: "recordId = %@", args: [notification.referId])
                .map { $0.first }
                .subscribe(onNext: { (bookRequest) in
                    var bookRequest = bookRequest
                    if bookRequest == nil {
                        bookRequest = BookRequest()
                        bookRequest?.recordId = notification.referId
                    }
                    vc?.bookRequest.onNext(bookRequest!)
                })
                .disposed(by: self.disposeBag)
        } else if segue.identifier == Gat.Segue.SHOW_MAP_LOCATION_IDENTIFIER {
            let vc = segue.destination as? MapViewController
            vc?.isEditMap.onNext(true)
            vc?.isUpdating.onNext(true)
        } else if segue.identifier == Gat.Segue.SHOW_FAVOURITE_CATEGORY_IDENTIFIER {
            let vc = segue.destination as? FavoriteCategoryViewController
            vc?.isEditingFavourite.onNext(false)
        } else if segue.identifier == Gat.Segue.openVisitorPage {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        } else if segue.identifier == FollowViewController.segueIdentifier {
            let vc = segue.destination as? FollowViewController
            vc?.type.onNext(.follower)
            vc?.user.onNext(Repository<UserPrivate, UserPrivateObject>.shared.get()?.profile ?? Profile())
        } else if segue.identifier == "showBookDetail" {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == "showChallengeDetail" {
            let vc = segue.destination as? ChallengeDetailVC
            vc?.idChallenge = sender as! Int
        } else if segue.identifier == PostDetailViewController.segueIdentifier {
            let vc = segue.destination as? PostDetailViewController
            vc?.presenter = SimplePostDetailPresenter(post: sender as! Post, imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: vc))
        }
    }
}

extension NotificationViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= (tableView.contentSize.height - self.tableView.frame.height) {
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

extension NotificationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = Bundle.main.loadNibNamed(Gat.View.HEADER, owner: self, options: nil)?.first as! HeaderSearch
        header.showView.isHidden = true
        header.backgroundColor = HEADER_NOTIFICATION_COLOR
        header.titleLabel.attributedText = NSAttributedString(string: (try? self.items.value()[section].model) ?? "", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0), NSAttributedString.Key.foregroundColor: TITLE_HEADER_NOTIFICATION_COLOR])
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.05 * tableView.frame.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 0.15 * tableView.frame.height
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
