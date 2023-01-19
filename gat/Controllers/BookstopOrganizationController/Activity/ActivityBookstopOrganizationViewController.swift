//
//  ActivityBookstopOrganizationViewController.swift
//  gat
//
//  Created by jujien on 7/27/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ActivityBookstopOrganizationViewController: UIViewController {
    
    class var segueIdentifier: String { "showActivityBookstopOrganization"}
    
    let bookstop: BehaviorRelay<Bookstop> = .init(value: .init())
    fileprivate let page = BehaviorSubject<Int>(value: 1)
    fileprivate var showStatus: SearchState = .new
    fileprivate let disposeBag = DisposeBag()
    fileprivate let memberActivities = BehaviorRelay<[MemberActivity]>(value: [])
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getMemberActivity()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getMemberActivity() {
        Observable<(Bookstop, Int)>
            .combineLatest(self.bookstop, self.page, resultSelector: { ($0, $1) })
            .filter { _ in Status.reachable.value }
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .memeberActivities(in: $0, page: $1)
                    .catchError({ (error) -> Observable<[MemberActivity]> in
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            }
            .subscribe(onNext: { [weak self] (memberActivities) in
                guard let status = self?.showStatus, var value = self?.memberActivities.value else {
                    return
                }
                switch status {
                case .new:
                    value = memberActivities
                    break
                case .more:
                    value.append(contentsOf: memberActivities)
                    break
                }
                self?.memberActivities.accept(value)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = "MEMBER_ACTIVITIES_TITLE_BOOKSTOPORGANIZATION".localized()
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UINib(nibName: MemberActivityTableViewCell.className, bundle: nil), forCellReuseIdentifier: "memberActivityCell")
        self.memberActivities.bind(to: self.tableView.rx.items(cellIdentifier: "memberActivityCell", cellType: MemberActivityTableViewCell.self)) { (index, activity, cell) in
            cell.setup(memberActivity: activity)
            cell.delegate = self
        }.disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
    }

    fileprivate func backEvent() {
        self.backButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }
}

extension ActivityBookstopOrganizationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height * 0.14
    }
    
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

extension ActivityBookstopOrganizationViewController: MemberActivityCellDelegate {

    func showView(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }

    func showViewController(_ vc: UIViewController) {
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        }
        else if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            let userPublic = UserPublic()
            userPublic.profile = sender as! Profile
            vc?.userPublic.onNext(userPublic)
        }
    }
}
