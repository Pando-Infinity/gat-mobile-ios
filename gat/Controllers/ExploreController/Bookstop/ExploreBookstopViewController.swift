//
//  ExploreBookstopViewController.swift
//  gat
//
//  Created by Vũ Kiên on 06/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import XLPagerTabStrip
import CoreLocation

class ExploreBookstopViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var showStatus = SearchState.new
    fileprivate var bookstops: [Bookstop] = []
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable<(CLLocationCoordinate2D, Int, Bool)>
            .combineLatest(self.getLocation(), self.page, Status.reachable.asObservable(), resultSelector: { ($0, $1, $2) })
            .filter { (_, _, status) in status }
            .map { (location, page, _) in (location, page) }
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .findBookstop(location: $0, searchKey: "", option: .all, showDetail: .detail, sortingBy: .newest, page: $1)
                    .catchError { (error) -> Observable<[Bookstop]> in
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { [weak self] (bookstops) in
                guard let status = self?.showStatus else {
                    return
                }
                switch status {
                case .new:
                    self?.bookstops = bookstops
                    break
                case .more:
                    self?.bookstops.append(contentsOf: bookstops)
                    break
                }
                self?.tableView.reloadData()
//                self?.tableView.reloadSections(.init(integer: 1), with: .automatic)
            })
            .disposed(by: self.disposeBag)
        
    }
    
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
                    return CLLocationCoordinate2D(latitude: 21.022736, longitude: 105.8019441)
                }
        }
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.registerNearbyBookstopCell()
        self.registerNewBookstopCell()
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
    }
    
    fileprivate func registerNearbyBookstopCell() {
        let nib = UINib(nibName: "NearbyBookstopTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "nearbyBookstopTableCell")
    }
    
    fileprivate func registerNewBookstopCell() {
        let nib = UINib(nibName: "NewBookstopTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "newBookstopCell")
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        LanguageHelper.changeEvent.subscribe(onNext: self.tableView.reloadData).disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBookstopOrganization" {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        } else if segue.identifier == Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER {
            let vc = segue.destination as? BookStopViewController
            vc?.bookstop.onNext(sender as! Bookstop)
        }
    }

}

extension ExploreBookstopViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return self.bookstops.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nearbyBookstopTableCell", for: indexPath) as! NearbyBookstopTableViewCell
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "newBookstopCell", for: indexPath) as! NewBookstopTableViewCell
            cell.delegate = self
            cell.setup(bookstop: self.bookstops[indexPath.row])
            return cell
        }
    }
}

extension ExploreBookstopViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 150.0
        } else {
            return 260.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = Bundle.main.loadNibNamed("HeaderSearch", owner: self, options: nil)?.first as? HeaderSearch
        if section == 0 {
            view?.titleLabel.text = Gat.Text.BookstopExplore.NEARBY_BOOKSTOP_TITLE.localized()
        } else {
            if self.bookstops.isEmpty {
                return UIView()
            } else {
                view?.titleLabel.text = Gat.Text.BookstopExplore.NEW_BOOKSTOP_TITLE.localized()
            }
            
        }
        view?.titleLabel.textColor = .black
        view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
        view?.backgroundColor = .white
        view?.showView.isHidden = true
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35.0 * tableView.frame.height / 667.0
    }
}

extension ExploreBookstopViewController {
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
                self.showStatus = .more
                self.page.onNext(1)
            }
        }
    }
}

extension ExploreBookstopViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension ExploreBookstopViewController: HomeDelegate {
    func showView(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension ExploreBookstopViewController: NewBookstopCellDelegate {
    func showViewController(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension ExploreBookstopViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return .init(title: Gat.Text.BookstopExplore.TITLE.localized().uppercased())
    }
    
    
}
