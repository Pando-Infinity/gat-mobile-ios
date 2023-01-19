//
//  MemberBookstopViewController.swift
//  gat
//
//  Created by Vũ Kiên on 16/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class MemberBookstopViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var numberLabel: UILabel!
    
    let bookstop: BehaviorSubject<Bookstop> = .init(value: Bookstop())
    fileprivate let members = BehaviorSubject<[UserPublic]>(value: [])
    fileprivate let page = BehaviorSubject<Int>(value: 1)
    fileprivate let disposeBag = DisposeBag()
    fileprivate var showStatus: SearchState = .new
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupUI()
        self.getData()
        self.requestJoin()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupJoinButton()
    }
    
    // MARK: - Request
    fileprivate func requestJoin() {
        self.joinButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.bookstop)
            .filter { $0.memberType == .open }
            .flatMapLatest { Observable<(Bookstop, RequestBookstopStatus)>.just(($0, .join)) }
            .filter { _ in Status.reachable.value }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .request(in: $0, with: $1)
                    .catchError { (error) -> Observable<()> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .flatMapLatest { [weak self] _ in self?.bookstop ?? Observable.empty() }
            .flatMapLatest { Repository<Bookstop, BookstopObject>.shared.save(object: $0) }
            .map { _ in 1 }
            .do(onNext: { [weak self] (_) in
                self?.joinButton.isHidden = true
                self?.showStatus = .new
            })
            .subscribe(self.page)
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable<(Bookstop, Int, Bool)>
            .combineLatest(self.bookstop, self.page, Status.reachable.asObservable(), resultSelector: { ($0, $1, $2) })
            .filter { (_, _, status) in status }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .map { (bookstop, page, _) in (bookstop, page) }
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .members(of: $0, page: $1)
                    .catchError { (error) -> Observable<[UserPublic]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { [weak self] (members) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let status = self?.showStatus, let value = try? self?.members.value(), var list = value else {
                    return
                }
                switch status {
                case .new:
                    list = members
                    break
                case .more:
                    list.append(contentsOf: members)
                    break
                }
                self?.members.onNext(list)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        let share = self.bookstop.compactMap { $0.kind as? BookstopKindOrganization }.share()
        share.map { "\($0.totalMemeber) \(Gat.Text.BookstopOrganization.MEMBERS_TITLE.localized())" }.bind(to: self.numberLabel.rx.text).disposed(by: self.disposeBag)
        share.map { $0.totalMemeber == 0 }.bind(to: self.numberLabel.rx.isHidden).disposed(by: self.disposeBag)
        self.setupTitle()
        self.setupTableView()
    }
    
    fileprivate func setupJoinButton() {
        Observable<(UserPrivate?, Bookstop)>
            .combineLatest(
                Repository<UserPrivate, UserPrivateObject>.shared.getAll().map{ $0.first },
                self.bookstop,
                resultSelector: { ($0, $1) }
            )
            .map({ (userPrivate, bookstop) -> Bool in
                let contain = userPrivate?.bookstops.filter { ($0.kind as? BookstopKindOrganization)?.status != nil }.contains(where: { $0.id == bookstop.id })
                if let c = contain {
                    return c
                } else {
                    return true
                }
            })
            .subscribe(self.joinButton.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        
        self.members
            .bind(to: self.tableView.rx.items(cellIdentifier: "memberCell", cellType: MemberTableViewCell.self))
            { (index, user, cell) in
                cell.setupUI(user: user)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTitle() {
        self.setupHeaderTitle(label: titleLabel)
        
    }
    
    fileprivate func setupHeaderTitle(label: UILabel) {
        self.bookstop.compactMap { $0.profile }.map { "Thành viên \($0.name)" }.bind(to: label.rx.text).disposed(by: self.disposeBag)
    }
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.joinEvent()
        self.tableViewEvent()
    }
    
    fileprivate func tableViewEvent() {
        self.tableView
            .rx
            .modelSelected(UserPublic.self)
            .subscribe(onNext: { [weak self] (userPublic) in
                if Repository<UserPrivate, UserPrivateObject>.shared.get()?.id == userPublic.profile.id {
                    let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                    vc.isShowButton.onNext(true)
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    self?.performSegue(withIdentifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: userPublic)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func joinEvent() {
        self.joinButton
            .rx
            .controlEvent(.touchUpInside)
            .withLatestFrom(self.bookstop)
            .filter { $0.memberType == .closed }
            .subscribe(onNext: { [weak self] (bookstop) in
                let storyboard = UIStoryboard(name: "Barcode", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: JoinBarcodeViewController.className) as! JoinBarcodeViewController
                vc.bookstop = bookstop
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        }
    }

}

extension MemberBookstopViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
}

extension MemberBookstopViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= (tableView.contentSize.height - self.tableView.frame.height) {
            if transition.y < -100 {
                self.showStatus = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if Status.reachable.value {
            let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
            if scrollView.contentOffset.y == 0 {
                if transition.y > 150 {
                    self.showStatus = .new
                    self.page.onNext(1)
                }
            }
        }
    }
}

extension MemberBookstopViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
