//
//  ActiveMembersVC.swift
//  gat
//
//  Created by Hung Nguyen on 1/25/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import SwipeMenuViewController
import RxSwift
import RxCocoa

class ActiveMembersVC: BaseViewController {
    
    override class var storyboardName: String {return "ActiveMembersView"}
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ivAvatarRank1: UIImageView!
    @IBOutlet weak var lbNameRank1: UILabel!
    @IBOutlet weak var lbTargetRank1: UILabel!
    @IBOutlet weak var book1TitleLabel: UILabel!
    @IBOutlet weak var book2TitleLabel: UILabel!
    @IBOutlet weak var book3TitleLabel: UILabel!
    
    @IBOutlet weak var ivAvatarRank2: UIImageView!
    @IBOutlet weak var lbNameRank2: UILabel!
    @IBOutlet weak var lbTargetRank2: UILabel!
    
    @IBOutlet weak var ivAvatarRank3: UIImageView!
    @IBOutlet weak var lbNameRank3: UILabel!
    @IBOutlet weak var lbTargetRank3: UILabel!
    
    private let getLeaderBoard = BehaviorRelay<ActiveMembersViewModel.ParamLeaderBoard?>(value: nil)
    private let getFriendLeaderBoard = BehaviorRelay<ActiveMembersViewModel.ParamLeaderBoard?>(value: nil)
    
    @IBOutlet weak var swipeMenuView: SwipeMenuView!
    
    var isShowFollowTab: Bool = false
    var challenge: Challenge!
    
    private var allMembersVC = ActiveMembersTabVC()
    private var friendMembersVC = ActiveMembersTabVC()
    
    private var viewModelMembers: ActiveMembersViewModel!
    private let getData = PublishSubject<Int>()
    private var leaderBoards: [LeaderBoard] = []
    private var friendLeaderBoards : [LeaderBoard] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.book1TitleLabel.text = "BOOK".localized()
        self.book2TitleLabel.text = "BOOK".localized()
        self.book3TitleLabel.text = "BOOK".localized()
        
        initNavigationBar()
        
        // Init Swipe Menu
        initSwipeMenu()
        
        bindViewModel()
        
        self.allMembersVC.tableViewMembers.rx.willBeginDecelerating
            .withLatestFrom(Observable.just(self.allMembersVC.tableViewMembers))
            .filter { (tableView) -> Bool in
                let transition = tableView.panGestureRecognizer.translation(in: tableView.superview)
                if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.height) {
                    if transition.y < -70 {
                        return true
                    }
                }
                return false
        }
        .subscribe(onNext: { (_) in
            guard let param = self.getLeaderBoard.value else { return }
            self.getLeaderBoard.accept(.init(challengeId: param.challengeId, pageNum: param.pageNum + 1))
            }).disposed(by: disposeBag)
        
        self.friendMembersVC.tableViewMembers.rx.willBeginDecelerating
            .withLatestFrom(Observable.just(self.friendMembersVC.tableViewMembers))
            .filter { (tableView) -> Bool in
                let transition = tableView.panGestureRecognizer.translation(in: tableView.superview)
                if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.height) {
                    if transition.y < -70 {
                        return true
                    }
                }
                return false
        }
        .subscribe(onNext: { (_) in
            guard let param = self.getFriendLeaderBoard.value else { return }
            self.getFriendLeaderBoard.accept(.init(challengeId: param.challengeId, pageNum: param.pageNum + 1))
            }).disposed(by: disposeBag)
        
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.followMemberEvent()
        self.onUpdateProgressEvent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        SwiftEventBus.unregister(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.navigationBar.barStyle = .black
    }
    
    private func initNavigationBar() {
        self.titleLabel.text = "ACTIVE_MEMBERS_TITLE".localized()
        setTitleNavigationBar(title: "ACTIVE_MEMBERS_TITLE".localized())
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.backgroundColor = Colors.transparent
        }
    }
    
    private func initSwipeMenu() {
        swipeMenuView.delegate = self
        swipeMenuView.dataSource = self
        
        var options: SwipeMenuViewOptions = .init()
        options.tabView.style = .segmented
        options.tabView.itemView.textColor = Colors.blueLight
        options.tabView.itemView.selectedTextColor = Colors.blueDark
        options.tabView.additionView.backgroundColor = Colors.blueDark
        swipeMenuView.reloadData(options: options)
        
        if isShowFollowTab {
            swipeMenuView.jump(to: 1, animated: true)
        }
    }
    
    private func bindViewModel() {
        self.getLeaderBoard.accept(.init(challengeId: self.challenge.id, pageNum: 1))
        self.getFriendLeaderBoard.accept(.init(challengeId: self.challenge.id, pageNum: 1))
        let useCase = Application.shared.networkUseCaseProvider
        viewModelMembers = ActiveMembersViewModel(useCase: useCase.makeLeaderBoardsUseCase())
        
        let input = ActiveMembersViewModel.Input(
            getData: self.getData,
            getLeaderBoards: self.getLeaderBoard, getFriendLeaderBoards: self.getFriendLeaderBoard
        )
        let output = viewModelMembers.transform(input)
        
        // Bind data for Leaderboard
//        output.leaderBoards.subscribe(onNext: { [weak self] result in
//            guard let it = result.leaderBoards, let challenge = self?.challenge else { return }
//
//            self?.allMembersVC.setData(leaderBoards: it, challenge: challenge)
//            self?.setTopRank(leaderBoards: it)
//            self?.leaderBoards = it
//        }).disposed(by: disposeBag)
        
        // Bind data for Friend Leaderboard
        output.friendLeaderBoards.subscribe(onNext: { [weak self] result in
            guard let it = result.leaderBoards,let param = self?.getFriendLeaderBoard.value , var leaderboard = self?.friendLeaderBoards, let challenge = self?.challenge else { return }
            if param.pageNum == 1 {
                leaderboard = it
            } else {
                leaderboard.append(contentsOf: it)
            }
            self?.friendMembersVC.setData(leaderBoards: leaderboard, challenge: challenge)
            self?.friendLeaderBoards = leaderboard
            
        }).disposed(by: disposeBag)
        
        output.leaderBoards
        .subscribe(onNext: { [weak self] result in
            guard let it = result.leaderBoards, let param = self?.getLeaderBoard.value, var leaderBoard = self?.leaderBoards, let challenge = self?.challenge else { return }
            if param.pageNum == 1 {
                leaderBoard = it
            } else {
                leaderBoard.append(contentsOf: it)
            }
            self?.allMembersVC.setData(leaderBoards: leaderBoard, challenge: challenge)
            self?.leaderBoards = leaderBoard
            self?.setTopRank(leaderBoards: leaderBoard)
        }).disposed(by: disposeBag)
        
        output.error
        .drive(rx.error)
        .disposed(by: disposeBag)
        
        output.indicator
        .drive(rx.isLoading)
        .disposed(by: disposeBag)
        
        getData.onNext(challenge.id)
    }
    
    private func setTopRank(leaderBoards: [LeaderBoard]) {
        // Set data for user rank 1
        if (leaderBoards.count >= 1) {
            self.ivAvatarRank1.setCircleWithBorder(imageId: leaderBoards[0].user?.imageId ?? "")
            self.lbNameRank1.text = leaderBoards[0].user?.name ?? ""
            self.lbTargetRank1.text = String(leaderBoards[0].progress)
        }
        
        // Set data for user rank 2
        if (leaderBoards.count >= 2) {
            self.ivAvatarRank2.setCircleWithBorder(imageId: leaderBoards[1].user?.imageId ?? "")
            self.lbNameRank2.text = leaderBoards[1].user?.name ?? ""
            self.lbTargetRank2.text = String(leaderBoards[1].progress)
        }
        
        // Set data for user rank 3
        if (leaderBoards.count >= 3) {
            self.ivAvatarRank3.setCircleWithBorder(imageId: leaderBoards[2].user?.imageId ?? "")
            self.lbNameRank3.text = leaderBoards[2].user?.name ?? ""
            self.lbTargetRank3.text = String(leaderBoards[2].progress)
        }
    }
    
    private func onUpdateProgressEvent() {
        SwiftEventBus.onMainThread(self, name: ActiveMemberUpdateReadingEvent.EVENT_NAME) { result in
            self.performSegue(withIdentifier: "showReadings", sender: nil)
        }
    }
    
    fileprivate func event() {
        Observable.of(
            self.ivAvatarRank1.rx.tapGesture().when(.recognized),
            self.ivAvatarRank2.rx.tapGesture().when(.recognized),
            self.ivAvatarRank3.rx.tapGesture().when(.recognized)
        ).merge()
            .subscribe(onNext: { [weak self] (gesture) in
                guard let leaderBoards = self?.leaderBoards, !leaderBoards.isEmpty else { return }
                let users = leaderBoards.compactMap { $0.user }.map { (user) -> UserPublic in
                    let userPublic = UserPublic()
                    userPublic.profile.id = user.id
                    userPublic.profile.name = user.name
                    userPublic.profile.imageId = user.imageId
                    return userPublic
                }
                guard !users.isEmpty else { return }
                switch gesture.view {
                case self?.ivAvatarRank1: self?.showUser(users[0])
                case self?.ivAvatarRank2 where users.count >= 2: self?.showUser(users[1])
                case self?.ivAvatarRank3 where users.count >= 3: self?.showUser(users[2])
                default: break
                }
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func showUser(_ user: UserPublic) {
        if user.profile.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
            let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
            vc.isShowButton.onNext(true)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
           self.performSegue(withIdentifier: "showUserVistor", sender: user)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showUserVistor" {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        }
    }
    
    private func followMemberEvent() {
        SwiftEventBus.onMainThread(self, name: FollowMemberEvent.EVENT_NAME) { result in
            let event: FollowMemberEvent? = result?.object as? FollowMemberEvent
            
            guard let it = event else { return }
            print("event isFollow: \(it.isFollow), userId: \(it.userId)")
            if it.isFollow {
                // Current is follow so should unfollow
                self.showAlertUnfollow(it.userId, it.userName)
            } else {
                // Current is unfollow so should follow
                self.followMember(userId: it.userId)
            }
        }
    }
    
    private func followMember(userId: Int) {
        self.view.isUserInteractionEnabled = false
        UserFollowService.shared
        .follow(userId: userId)
        .catchError({ [weak self] (error) -> Observable<()> in
            self?.view.isUserInteractionEnabled = false
            HandleError.default.showAlert(with: error)
            return Observable.empty()
        })
        .subscribe(onNext: { [weak self] (status) in
            ToastView.makeToast("MESSAGE_FOLLOW_MEMBER_SUCCESS".localized())
            // Update data
            self?.view.isUserInteractionEnabled = true
            self?.getData.onNext(self?.challenge.id ?? 0)
        })
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func showAlertUnfollow(_ userId: Int, _ userName: String) {
        let unfollow = ActionButton(titleLabel: Gat.Text.UNFOLLOW_TITLE.localized()) { [weak self] in
            ToastView.makeToast("MESSAGE_UNFOLLOW_MEMBER_SUCCESS".localized())
            // Update data
            self?.unFollowMember(userId: userId)
        }
        let cancel = ActionButton(titleLabel: Gat.Text.CommonError.CANCEL_ERROR_TITLE.localized(), action: nil)
        AlertCustomViewController.showAlert(title: String(format: Gat.Text.UNFOLLOW_ALERT_TITLE.localized(), userName), message: String(format: Gat.Text.UNFOLLOW_MESSAGE.localized(), userName), actions: [unfollow, cancel], in: self)
    }
    
    private func unFollowMember(userId: Int) {
        self.view.isUserInteractionEnabled = false
        UserFollowService.shared
        .unfollow(userId: userId)
        .catchError({ [weak self] (error) -> Observable<()> in
            HandleError.default.showAlert(with: error)
            self?.view.isUserInteractionEnabled = true
            return Observable.empty()
        })
        .subscribe(onNext: { [weak self] (status) in
            print("add unfollow success")
            // Update data
            self?.view.isUserInteractionEnabled = true
            self?.getData.onNext(self?.challenge.id ?? 0)
            
        })
        .disposed(by: self.disposeBag)
    }
}

extension ActiveMembersVC: SwipeMenuViewDelegate {
    // MARK - SwipeMenuViewDelegate
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewWillSetupAt currentIndex: Int) {
        // Codes
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewDidSetupAt currentIndex: Int) {
        // Codes
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, willChangeIndexFrom fromIndex: Int, to toIndex: Int) {
        // Codes
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, didChangeIndexFrom fromIndex: Int, to toIndex: Int) {
        // Codes
    }
}

extension ActiveMembersVC: SwipeMenuViewDataSource {
    // MARK - SwipeMenuViewDataSource

    func numberOfPages(in swipeMenuView: SwipeMenuView) -> Int {
        return 2
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, titleForPageAt index: Int) -> String {
        var title = "TOTAL_ACTIVE_MEMBERS".localized()
        if index == 1 {
            title = "FOLLOWING_ACTIVE_MEMBERS".localized()
        }
        return title
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewControllerForPageAt index: Int) -> UIViewController {
        let viewController: UIViewController
        switch index {
            case 0:
                viewController = allMembersVC
            case 1:
                viewController = friendMembersVC
            default:
                viewController = allMembersVC
        }
        addChild(viewController)
        return viewController
    }
}


