//
//  NearByUserController.swift
//  gat
//
//  Created by Vũ Kiên on 06/03/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import CoreLocation

class NearByUserController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var containerMapView: UIView!
    @IBOutlet weak var loading: UIImageView!
    @IBOutlet weak var titleConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate var mapView: MapView!
    fileprivate var header: HeaderSearch!
    
    let locationInEdgeMap: BehaviorSubject<(CLLocationCoordinate2D, CLLocationCoordinate2D)> = .init(value: (CLLocationCoordinate2D(), CLLocationCoordinate2D()))
    let users: BehaviorSubject<[UserPublic]> = .init(value: [])
    fileprivate var status: SearchState = .new
    fileprivate let disposeBag = DisposeBag()
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    
    fileprivate let totalResult: BehaviorSubject<Int> = .init(value: 0)
    
    
    //MARK: - STATEVIEW
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
        self.getNearByUser()
    }
    
    //MARK: - Data
    fileprivate func getLocation() -> Observable<CLLocationCoordinate2D> {
        return LocationManager
            .manager
            .location
            .catchError { (error) -> Observable<CLLocationCoordinate2D> in
                return Repository<UserPrivate, UserPrivateObject>
                    .shared.getFirst()
                    .flatMapLatest({ (userPrivate) -> Observable<CLLocationCoordinate2D> in
                        return Observable<CLLocationCoordinate2D>.from(optional: userPrivate.profile?.location)
                    })
            }
            .map { (location) -> CLLocationCoordinate2D in
                if (location != CLLocationCoordinate2D()) {
                    return location
                } else {
                    return CLLocationCoordinate2D.init(latitude: 21.022736, longitude: 105.8019441)
                }
        }
    }
    
    fileprivate func getNearByUser() {
        Observable<(CLLocationCoordinate2D, CLLocationCoordinate2D, CLLocationCoordinate2D, Int, Bool)>
            .combineLatest(
                self.getLocation(),
                self.locationInEdgeMap,
                self.page,
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1.0, $1.1, $2, $3) }
            )
            .filter { (location, northEast, southWest, _, status) in location != CLLocationCoordinate2D() && northEast != CLLocationCoordinate2D() && southWest != CLLocationCoordinate2D() && status }
            .do(onNext: { [weak self] (_) in
                self?.waitInteracter(true)
            })
            .map { (location, northEast, southWest, page, _) in (location, northEast, southWest, page) }
            .flatMapLatest { [weak self] (location, northEast, southWest, page) in
                SearchNetworkService
                    .shared
                    .findNearBy(currentLocation: location, northEast: northEast, southWest: southWest, page: page)
                    .catchError { [weak self] (error) -> Observable<([UserPublic], Int?)> in
                        self?.waitInteracter(false)
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { [weak self] (list, total) in
                self?.waitInteracter(false)
                if let count = total {
                    self?.totalResult.onNext(count)
                }
                guard let value = try? self?.users.value(), var users = value, let status = self?.status else {
                    return
                }
                switch status {
                case .new:
                    users = list
                    break
                case .more:
                    users.append(contentsOf: list)
                    break
                }
                self?.users.onNext(users)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = Gat.Text.NearByUser.NEARBY_USER_TITLE.localized()
        self.setupTableView()
        self.setupMapView()
        self.loadingUI()
        self.setupMessage()
    }
    
    fileprivate func loadingUI() {
        if let url = AppConfig.sharedConfig.getUrlFile(LOADING_GIF, withExtension: EXTENSION_GIF) {
            self.loading.sd_setImage(with: url)
        }
        self.loading.isHidden = true
    }
    
    fileprivate func setupMessage() {
        self.messageLabel.text = Gat.Text.NearByUser.NOT_FOUND_NEARBY_USER_MESSAGE.localized()
        self.messageLabel.isHidden = true
        self.users
            .skip(1)
            .map { !$0.isEmpty }
            .subscribe(self.messageLabel.rx.isHidden)
            .disposed(by: self.disposeBag)
    }

    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.users
            .bind(to: self.tableView.rx.items(cellIdentifier: Gat.Cell.IDENTIFIER_FRIEND, cellType: FriendTableViewCell.self))
            {
                (row, user, cell) in
                cell.setup(user: user)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupHeader(count: Int) {
        if self.header == nil {
            self.header = Bundle.main.loadNibNamed(Gat.View.HEADER, owner: self, options: nil)?.first as? HeaderSearch
            self.header.frame = CGRect(x: 0.0, y: 0.0, width: self.tableView.frame.width, height: self.tableView.frame.height * 0.08)
            self.header.showView.isHidden = true
            self.header.backgroundColor = .white
        }
        var countString = ""
        var range: NSRange!
        if count <= 9 {
            countString = "0\(count)"
        } else {
            countString = "\(count)"
        }
        let attributes = NSMutableAttributedString(string: String(format: Gat.Text.NearByUser.RESULT_HEADER_TITLE.localized(), countString), attributes: [NSAttributedString.Key.foregroundColor: SHOW_TITLE_TEXT_COLOR, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.regular)])
        
        range = (String(format: Gat.Text.NearByUser.RESULT_HEADER_TITLE.localized(), countString) as NSString).range(of: countString)
        attributes.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.semibold)], range: range)
        
        self.header.titleLabel.attributedText = attributes
    }
    
    fileprivate func setupMapView() {
        self.mapView = Bundle.main.loadNibNamed(Gat.View.MAP, owner: self, options: nil)?.first as? MapView
        self.mapView.frame = self.containerMapView.bounds
        self.mapView.viewcontroller = self
        self.mapView.event()
        self.containerMapView.addSubview(mapView)
    }
    
    func waitInteracter(_ isWait: Bool) {
        self.loading.isHidden = !isWait
        self.containerMapView.isUserInteractionEnabled = !isWait
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
        self.tableViewSelectEvent()
        self.totalResultChangedEvent()
        self.locationInEdgeMap
            .subscribe(onNext: { [weak self] (_) in
                self?.status = .new
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func permissionLocation() {
        LocationManager
            .manager
            .permission
            .asObservable()
            .bind { (permission) in
                guard let vc = UIApplication.topViewController(), !permission else {
                    return
                }
                let actionSetting = ActionButton(titleLabel: Gat.Text.Home.SETTING_ALERT_TITLE.localized(), action: {
                    guard let url = URL(string: Gat.Prefs.OPEN_PRIVACY) else {
                        return
                    }
                    guard UIApplication.shared.canOpenURL(url) else {
                        return
                    }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                })
                AlertCustomViewController.showAlert(title: Gat.Text.Home.ERROR_ALERT_TITLE.localized(), message: Gat.Text.CommonError.ERROR_GPS_MESSAGE.localized(), actions: [actionSetting], in: vc)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .bind { [weak self] in
                if self?.navigationController?.presentingViewController?.presentedViewController == self?.navigationController {
                    self?.dismiss(animated: true, completion: nil)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func tableViewSelectEvent() {
        self.tableView
            .rx
            .modelSelected(UserPublic.self)
            .flatMapLatest { (user) -> Observable<(UserPublic, UserPrivate?)> in
                return Observable<(UserPublic, UserPrivate?)>
                    .combineLatest(Observable<UserPublic>.just(user), Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first }, resultSelector: {($0, $1)})
            }
            .bind { [weak self] (userPublic, userPrivate) in
                if userPublic.profile.userTypeFlag == .normal {
                    if let userId = userPrivate?.id, userId == userPublic.profile.id {
                        let personStoryboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                        let vc = personStoryboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                        vc.isShowButton.onNext(true)
                        self?.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        self?.performSegue(withIdentifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: userPublic)
                    }
                } else if userPublic.profile.userTypeFlag == .bookstop {
                    let bookstop = Bookstop()
                    bookstop.id = userPublic.profile.id
                    bookstop.profile = userPublic.profile
                    self?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER, sender: bookstop)
                } else {
                    let bookstop = Bookstop()
                    bookstop.id = userPublic.profile.id
                    bookstop.profile = userPublic.profile
                    self?.performSegue(withIdentifier: "showBookstopOrganization", sender: bookstop)
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func totalResultChangedEvent() {
        self.totalResult
            .subscribe(onNext: { [weak self] (count) in
                self?.setupHeader(count: count)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as! UserVistorViewController
            vc.userPublic.onNext(sender as! UserPublic)
        } else if segue.identifier == Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER {
            let vc = segue.destination as? BookStopViewController
            vc?.bookstop.onNext(sender as! Bookstop)
        } else if segue.identifier == "showBookstopOrganization" {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        }
    }
}

extension NearByUserController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.tableView.frame.height * 0.075
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.header
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height / 4
    }
}

extension NearByUserController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= (tableView.contentSize.height - self.tableView.frame.height) {
            if transition.y < -35 {
                self.status = .more
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
            if transition.y > 50 {
                self.status = .new
                self.page.onNext(1)
            }
        }
    }
}

extension NearByUserController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
