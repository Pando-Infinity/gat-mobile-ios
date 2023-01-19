//
//  MessageViewController.swift
//  gat
//
//  Created by Vũ Kiên on 18/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class MessageViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var textView: UIView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var bottomMessageConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let group: BehaviorSubject<GroupMessage> = .init(value: GroupMessage())
    fileprivate var items = [Any]()
    fileprivate var observe: UInt = 0
    fileprivate var user: UserPrivate!
    fileprivate let disposeBag = DisposeBag()
    fileprivate let recommendMessage: BehaviorSubject<[String]> = .init(value: [])
    let lastUpdated: BehaviorRelay<Date?> = .init(value: nil)
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.getRecommendMessage()
        self.getData()
        self.sendMessage()
        self.event()
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.user = Repository<UserPrivate, UserPrivateObject>.shared.get()!
        self.getMessage()
        self.listenMessage()
        self.group.filter { !$0.groupId.isEmpty }.do(onNext: { (group) in
            group.lastMessage = group.messages.last
        }).flatMap { Repository<GroupMessage, GroupMessageObject>.shared.save(object: $0) }.subscribe().disposed(by: self.disposeBag)
        
    }
    
    fileprivate func getProfileIfNeeded() {
        guard let group = try? self.group.value(), group.users.last!.name.isEmpty else { return }
        UserNetworkService.shared.publicInfo(user: group.users.last!)
            .catchError { (error) -> Observable<UserPublic> in
                return Observable.empty()
        }.subscribe(onNext: { [weak self] (user) in
            group.users.removeLast()
            group.users.append(user.profile)
            self?.group.onNext(group)
        }).disposed(by: self.disposeBag)
    }

    fileprivate func getMessage() {
        let local = Repository<GroupMessage, GroupMessageObject>.shared.getAll(predicateFormat: "groupId = %@", args: [(try! self.group.value()).groupId])
            .do(onNext: { [weak self] (groups) in
                guard let group = groups.first, !group.messages.isEmpty && group.messages.count > 1 else {
                    self?.lastUpdated.accept(Date())
                    return
                }
                group.messages = group.messages.sorted(by: { $0.sendDate > $1.sendDate })
                if group.messages.last?.sendDate != group.lastUpdated && group.lastMessage?.messageId != group.messages.first?.messageId {
                    self?.lastUpdated.accept(Date())
                }
            })
            .map { $0.first?.messages ?? [] }
        
        let server = Observable<(String, Date?)>.combineLatest(self.group.filter { !$0.groupId.isEmpty }.elementAt(0).map { $0.groupId }, self.lastUpdated, resultSelector: { ($0, $1 )})
        .flatMap { MessageService.shared.message(in: $0, lastUpdate: $1).catchError({ (error) -> Observable<[Message]> in
            HandleError.default.showAlert(with: error)
            return Observable.empty()
        }) }
        Observable.of(local, server)
            .merge()
            .filter { !$0.isEmpty }
            .do(onNext: { [weak self] (messages) in
                var results = self?.items ?? []
                let day = AppConfig.sharedConfig.stringFormatter(from: messages.first!.sendDate, format: LanguageHelper.language == .japanese ? "yyyy MMMM dd" : "dd MMMM yyyy")
                if results.isEmpty { results.append(day) }
                let last = (try! self?.group.value())?.messages.last
                var scrollToTop = self?.lastUpdated.value != nil
                messages.enumerated().forEach { (offset, message) in
                    let calDay = AppConfig.sharedConfig.stringFormatter(from: message.sendDate, format: LanguageHelper.language == .japanese ? "yyyy MMMM dd" : "dd MMMM yyyy")
                    if let index = results.firstIndex(where: { $0 as? String != nil && $0 as! String == calDay }) {
                        if let messageIndex = results.firstIndex(where: { $0 as? Message != nil && ($0 as! Message).messageId == message.messageId }) {
                            results[messageIndex] = message
                        } else {
                            if last != nil && last!.sendDate < message.sendDate {
                                scrollToTop = false
                                if offset == 0 {
                                    results.append(message)
                                } else {
                                    results.insert(message, at: results.count - offset)
                                }
                            } else {
                                results.insert(message, at: index + 1)
                            }
                        }
                    } else {
                        if let messageIndex = results.firstIndex(where: { $0 as? Message != nil && ($0 as! Message).messageId == message.messageId }) {
                            results[messageIndex] = message
                        }
                        if last != nil && last!.sendDate < message.sendDate {
                            scrollToTop = false
                            results.append(calDay)
                            if offset == 0 {
                                results.append(message)
                            } else {
                                results.insert(message, at: results.count - offset)
                            }
                        } else {
                            results.insert(message, at: 0)
                            results.insert(calDay, at: 0)
                        }
                    }
                }
                self?.items = results
                self?.tableView.reloadData()
                if scrollToTop {
                    self?.tableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: true)
                } else {
                    self?.tableView.scrollToRow(at: IndexPath(item: results.count - 1, section: 0), at: .bottom, animated: true)
                }
            })
            .subscribe(onNext: { [weak self] (messages) in
                guard let value = try? self?.group.value(), let group = value else { return }
                messages.forEach { (message) in
                    if let index = group.messages.firstIndex(where: {$0.messageId == message.messageId}) {
                        group.messages[index] = message
                    } else {
                        group.messages.insert(message, at: 0)
                    }
                }
                if let user = group.users.first(where: { $0.id != Repository<UserPrivate, UserPrivateObject>.shared.get()?.id}), !user.name.isEmpty {
                    if let friend = messages.first(where: {$0.user?.id != Repository<UserPrivate, UserPrivateObject>.shared.get()?.id && $0.user?.id != 0 })?.user {
                        group.users.removeAll(where: {$0.id == user.id})
                        group.users.append(friend)
                    }
                }
                self?.group.onNext(group)
            })
            .disposed(by: self.disposeBag)
    }

    fileprivate func listenMessage() {
        self.group.filter { !$0.groupId.isEmpty }.elementAt(0)
            .flatMap {
            MessageService.shared.listen(in: $0.groupId)
                .catchError({ (error) -> Observable<Message> in
                    HandleError.default.showAlert(with: error)
                    return Observable.empty()
                })
            }
            .do(onNext: { [weak self] (message) in
                guard let value = try? self?.group.value(), let group = value else { return }
                if let index = group.messages.firstIndex(where: {$0.messageId == message.messageId }) {
                    group.messages[index] = message
                } else {
                    group.messages.append(message)
                }
                group.lastMessage = message
                self?.group.onNext(group)
            })
            .subscribe(onNext: { [weak self] (message) in
                let calDay = AppConfig.sharedConfig.stringFormatter(from: message.sendDate, format: LanguageHelper.language == .japanese ? "yyyy MMMM dd" : "dd MMMM yyyy")
                let lastCalDay = self?.items.compactMap { $0 as? String }.last
                if calDay != lastCalDay {
                    self?.items.append(calDay)
                }
                self?.items.append(message)
                self?.tableView.reloadData()
                self?.tableView.scrollToRow(at: .init(row: (self?.items.count ?? 1) - 1 , section: 0), at: .bottom, animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getRecommendMessage() {
        self.group.map { $0.users.first(where: {$0.id != Repository<UserPrivate, UserPrivateObject>.shared.get()?.id }) }
            .flatMap { Observable.from(optional: $0) }
            .flatMap { (user) -> Observable<[String]> in
                return Observable<[String]>
                    .just([
                        String(format: Gat.Text.Message.RECOMMEND_MESSAGE_1.localized(), user.name),
                        String(format: Gat.Text.Message.RECOMMEND_MESSAGE_2.localized(), user.name),
                        Gat.Text.Message.RECOMMEND_MESSAGE_3.localized()
                        ])
            }
            .subscribe(self.recommendMessage)
            .disposed(by: self.disposeBag)
        
        GoogleMapService
            .default
            .address()
            .subscribe(onNext: { [weak self] (address) in
                guard let value = try? self?.recommendMessage.value(), var list = value else {
                    return
                }
                list.append(String(format: Gat.Text.Message.RECOMMEND_MESSAGE_4.localized(), address))
                self?.recommendMessage.onNext(list)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func sendMessage() {
        self.sendButton.rx.tap.asObservable()
            .filter { [weak self]  _ in !(self?.messageTextField.text?.isEmpty ?? true) }
            .map { [weak self] (_) -> Message in
                let sendDate = Date()
                let profile = Repository<UserPrivate, UserPrivateObject>.shared.get()!
                let messageId = "\(Int64(sendDate.timeIntervalSince1970 * 1000.0))_\(profile.id)"
                return Message(messageId: messageId, user: profile.profile, type: .text, content: self?.messageTextField.text ?? "", description: "", sendDate: sendDate, readTime: ["\(profile.id)": sendDate])
            }
            .do(onNext: { [weak self] (_) in
                self?.messageTextField.text = ""
            })
            .withLatestFrom(self.group, resultSelector: {($0, $1)})
            .filter { _ in Status.reachable.value }
            .flatMap { (message, group) -> Observable<()> in
                guard let friend = group.users.first(where: {$0.id != Repository<UserPrivate, UserPrivateObject>.shared.get()?.id }) else { return  Observable.empty() }
                return Observable.combineLatest(MessageService.shared.send(message: message, in: group), NotificationNetworkService.shared.push(receiver: friend, message: message.content).catchErrorJustReturn(()), resultSelector: { ($0, $1)})
                    .catchError({ (error) -> Observable<((), ())> in
                        print(error.localizedDescription)
                        return Observable.just(((), ()))
                    }).map { $0.0 }
            }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.nameLabel.isUserInteractionEnabled = true
        self.group.map { $0.users.first(where: {$0.id != Repository<UserPrivate, UserPrivateObject>.shared.get()?.id }) }.map { $0?.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.sendButton.setTitle(Gat.Text.Message.SEND_MESSAGE_TITLE.localized(), for: .normal)
        self.setupTextField()
        self.setupTableView()
        self.setupCollectionView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.estimatedRowHeight = 60.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self
        self.recommendMessage
            .bind(to: self.collectionView.rx.items(cellIdentifier: RecommendMessageCollectionViewCell.identifier, cellType: RecommendMessageCollectionViewCell.self))
            { (index, message, cell) in
                cell.messageLabel.text = message
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTextField() {
        self.view.layoutIfNeeded()
        self.textView.cornerRadius(radius: self.messageTextField.frame.height / 2.0)
        self.textView.layer.borderColor = BACKGROUND_MESSAGE_COLOR.cgColor
        self.textView.layer.borderWidth = 0.5
        self.messageTextField.attributedPlaceholder = .init(string: Gat.Text.Message.PLACEHOLDER_MESSAGE_TITLE.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
    }
    
    fileprivate func changeLayout(constant: CGFloat) {
        self.view.layoutIfNeeded()
        self.bottomMessageConstraint.constant = constant
        self.view.layoutIfNeeded()
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
        self.didBeginEditingEvent()
        self.showUserVistor()
        self.collectionViewEvent()
        NotificationCenter.default.addObserver(self, selector: #selector(changeMessageView(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeMessageView(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
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
    
    fileprivate func didBeginEditingEvent() {
        self.messageTextField.rx.controlEvent(.editingDidBegin)
            .flatMap { [weak self] (_) -> Observable<GroupMessage> in
                guard let value = try? self?.group.value(), let group = value else { return Observable.empty() }
                let readDate = Date()
//                group.messages.forEach { (message) in
//                    message.readTime["\(Repository<UserPrivate, UserPrivateObject>.shared.get()!.id)"] = readDate
//                }
                if group.lastMessage?.isRead == false {
                    group.lastUpdated = readDate
                    group.lastMessage?.readTime["\(Repository<UserPrivate, UserPrivateObject>.shared.get()!.id)"] = readDate
                }
                return Observable.just(group)
            }
            .filter { !$0.messages.isEmpty }
            .flatMap { MessageService.shared.updateReadStatus(group: $0).catchErrorJustReturn(()) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showUserVistor() {
        self.nameLabel.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                guard let value = try? self?.group.value(), let group = value, let user = group.users.first(where: {$0.id != Repository<UserPrivate, UserPrivateObject>.shared.get()?.id }) else { return }
                let userPublic  = UserPublic()
                userPublic.profile = user
                self?.performSegue(withIdentifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: userPublic)
            })
            .disposed(by: self.disposeBag)
    }
    
    @objc
    fileprivate func changeMessageView(notification: Notification) {
        if notification.name == UIResponder.keyboardWillHideNotification {
            self.changeLayout(constant: 0)
            return
        }
        guard let frameKeyboard = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue  else {
            self.bottomMessageConstraint.constant = 0.0
            return
        }
        let heightKeyboard = frameKeyboard.cgRectValue.height
        self.changeLayout(constant: heightKeyboard)
        if !self.items.isEmpty {
            self.tableView.scrollToRow(at: IndexPath(row: self.items.count - 1, section: 0), at: .bottom, animated: false)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.messageTextField.resignFirstResponder()
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(String.self)
            .bind(to: self.messageTextField.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        }
    }
    
    //MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension MessageViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.items[indexPath.row]
        if let day = item as? String {
            let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_DAY, for: indexPath) as! DayTableViewCell
            cell.setup(day: day)
            return cell
        } else {
            let message = item as! Message
            if message.user?.id == self.user.id {
                let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_YOU_MESSAGE, for: indexPath) as! MessageYouTableViewCell
                cell.setupUI(message: message)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_FRIEND_MESSAGE, for: indexPath) as! MessageFriendTableViewCell
                cell.controller = self
                cell.setupUI(message: message)
                return cell
            }
        }
    }
}

extension MessageViewController: UITableViewDelegate {
    
}

extension MessageViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let value = try? self.recommendMessage.value() else {
            return .zero
        }
        return RecommendMessageCollectionViewCell.size(message: value[indexPath.row], collectionView: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
    }
}

extension MessageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MessageViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard Status.reachable.value, let group = try? self.group.value() else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if scrollView.contentOffset.y == 0 {
            if transition.y > 100 {
                if self.lastUpdated.value != group.messages.first?.sendDate {
                    self.lastUpdated.accept(group.messages.first?.sendDate)
                }
            }
        }
    }
}


