//
//  ListMessageViewController.swift
//  gat
//
//  Created by Vũ Kiên on 18/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SDWebImage

class ListMessageViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    fileprivate let groups: BehaviorSubject<[GroupMessage]> = .init(value: [])
    fileprivate let lastUpdate: BehaviorRelay<Date?> = .init(value: nil)
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.getListFromLocal()
        self.getList()
        self.listenList()
    }
    
    fileprivate func getListFromLocal() {
        Repository<GroupMessage, GroupMessageObject>.shared
            .getAll(sortBy: "lastUpdated", ascending: false)
            .map { $0.filter { $0.lastMessage != nil } }
            .do(onNext: { [weak self] (groups) in
                self?.lastUpdate.accept(groups.last?.lastUpdated ?? Date())
            })
            .flatMap { (groups) -> Observable<[GroupMessage]> in
                var newGroups = [GroupMessage]()
                return Observable.from(groups)
                    .flatMap { (group) -> Observable<GroupMessage> in
                        guard let user = group.users.last else { return .just(group) }
                        if !user.name.isEmpty {
                            return .just(group)
                        } else {
                            return UserNetworkService.shared.publicInfo(user: user)
                                .catchError { (error) -> Observable<UserPublic> in
                                    let userPublic = UserPublic()
                                    userPublic.profile = user
                                    return .just(userPublic)
                            }.do(onNext: { (user) in
                                group.users.removeLast()
                                group.users.append(user.profile)
                            })
                                .map { _ in group }
                        }
                }
                .do(onNext: { (group) in
                    newGroups.append(group)
                })
                    .filter { _ in newGroups.count == groups.count }
                    .map { _ in newGroups }
        }
        .subscribe(onNext: self.groups.onNext).disposed(by: self.disposeBag)
    }
    
    fileprivate func save(groups: [GroupMessage]) {
        Repository<GroupMessage, GroupMessageObject>.shared.save(objects: groups).subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func save(group: GroupMessage) {
        Repository<GroupMessage, GroupMessageObject>.shared.save(object: group).subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func getList() {
        self.lastUpdate.flatMap { (date) -> Observable<[GroupMessage]> in
            return MessageService.shared.groupsWithLastMessage(lastUpdated: date).catchError { (error) -> Observable<[GroupMessage]> in
                HandleError.default.showAlert(with: error)
                return Observable.just([])
            }
        }
        .subscribe(onNext: { [weak self] (lists) in
            guard let value = try? self?.groups.value(), var groups = value else { return }
            lists.forEach { (group) in
                if let index = groups.firstIndex(where: {$0.groupId == group.groupId}) {
                    groups[index].lastMessage = group.lastMessage
                    groups[index].lastUpdated = group.lastUpdated
                    groups[index].users = group.users
                    if groups[index].messages.filter ({ $0.messageId != group.lastMessage!.messageId }).isEmpty {
                        groups[index].messages.append(group.lastMessage!)
                    }
                } else {
                    groups.append(group)
                }
            }
            self?.save(groups: groups)
            self?.groups.onNext(groups)
        })
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func listenList() {
        MessageService.shared.listenGroupsWithLastMessage()
            .catchError { (error) -> Observable<GroupMessage> in
                return Observable.empty()
            }
            .subscribe(onNext: { [weak self] (group) in
                guard let value = try? self?.groups.value(), var groups = value else { return }
                if let index = groups.firstIndex(where: {$0.groupId == group.groupId}) {
                    groups[index].lastUpdated = group.lastUpdated
                    groups[index].lastMessage = group.lastMessage
                    groups[index].users = group.users
                    if groups[index].messages.filter ({ $0.messageId != group.lastMessage!.messageId }).isEmpty {
                        groups[index].messages.append(group.lastMessage!)
                    }
                    self?.save(group: groups[index])
                } else {
                    groups.insert(group, at: 0)
                }
                self?.groups.onNext(groups)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func sendReadMessage(group: GroupMessage) {
        guard group.lastMessage?.isRead == false else { return }
        let readDate = Date()
        group.lastMessage?.readTime["\(Repository<UserPrivate, UserPrivateObject>.shared.get()!.id)"] = readDate
        group.messages.last?.readTime["\(Repository<UserPrivate, UserPrivateObject>.shared.get()!.id)"] = readDate
        group.lastUpdated = readDate
        MessageService.shared.updateReadStatus(group: group)
            .catchErrorJustReturn(())
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = Gat.Text.Notification.MESSAGE_TITLE.localized()
        self.setupLoadingView()
        self.setupTableView()
        self.setupMessage()
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.groups
            .map({ (groups) -> [GroupMessage] in
                return groups.sorted(by: { $0.lastMessage!.sendDate > $1.lastMessage!.sendDate })
            })
            .bind(to: self.tableView.rx.items(cellIdentifier: Gat.Cell.IDENTIFIER_LIST_MESSAGES, cellType: ListMessageTableViewCell.self))
            { (row, group, cell) in
                cell.index = row
                cell.setup(group: group)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupMessage() {
        self.messageLabel.text = Gat.Text.Message.EMPTY_MESSAGE_TITLE.localized()
        self.messageLabel.isHidden = true
    }
    
    fileprivate func setupLoadingView() {
        if let url = AppConfig.sharedConfig.getUrlFile(LOADING_GIF, withExtension: EXTENSION_GIF) {
            self.loadingView.sd_setImage(with: url)
            self.loadingView.isHidden = true
        }
    }
    
    fileprivate func showAlert(title: String = Gat.Text.Message.ERROR_ALERT_TITLE.localized(), message: String, actions: [ActionButton]) {
        AlertCustomViewController.showAlert(title: title, message: message, actions: actions, in: self)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backButtonEvent()
        self.selectTableViewCellEvent()
    }
    
    fileprivate func backButtonEvent() {
        self.backButton
            .rx
            .tap
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                if self?.navigationController?.presentingViewController?.presentedViewController == self?.navigationController {
                    self?.dismiss(animated: true, completion: nil)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func selectTableViewCellEvent() {
        self.tableView
            .rx
            .modelSelected(GroupMessage.self)
            .subscribe(onNext: { [weak self] (groupMessage) in
                self?.sendReadMessage(group: groupMessage)
                self?.performSegue(withIdentifier: Gat.Segue.SHOW_MESSAGE_IDENTIFIER, sender: groupMessage)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_MESSAGE_IDENTIFIER {
            let vc = segue.destination as? MessageViewController
            let group = sender as! GroupMessage
            vc?.group.onNext(group)
        }
    }
}

extension ListMessageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 0.09 * tableView.frame.height
    }
}

extension ListMessageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension ListMessageViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value, let groups = try? self.groups.value() else { return }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= (tableView.contentSize.height - self.tableView.frame.height) {
            if transition.y < -70 {
                self.lastUpdate.accept(groups.last?.lastUpdated)
            }
        }
    }
}
