//
//  ActiveMembersTabVC.swift
//  gat
//
//  Created by Hung Nguyen on 1/28/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ActiveMembersTabVC: BaseViewController {
    
    let tableViewMembers = UITableView()
    
    private let leaderBoards: BehaviorRelay<[LeaderBoard]> = BehaviorRelay(value: [])
    private var challenge: Challenge?
    private var isFollowTab: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initView() {
        // Add tableView to main view
        view.addSubview(tableViewMembers)
        self.tableViewMembers.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        
        // Inti Cell
        let nib = UINib.init(nibName: "ActiveMemberCellLength", bundle: nil)
        self.tableViewMembers.register(nib, forCellReuseIdentifier: "ActiveMemberCellLength")
        // Set Cell height
        tableViewMembers.rowHeight = 76
        tableViewMembers.allowsSelection = false
        // Bind data to tableView
        leaderBoards.bind(to: self.tableViewMembers.rx.items(
            cellIdentifier: "ActiveMemberCellLength",
            cellType: ActiveMemberCellLength.self)
        ) { [weak self] (row, model, cell) in
            if let challenge = self?.challenge {
                cell.setData(model, challenge, row, self?.isFollowTab ?? false)

            }
            cell.showUser = self?.showUser
        }.disposed(by: disposeBag)
        tableViewMembers.backgroundColor = .clear
        tableViewMembers.tableFooterView = UIView()
    }
    
    fileprivate func showUser(_ profile: UserPublic) {
        if profile.profile.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
            let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
            vc.isShowButton.onNext(true)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let storyboard = UIStoryboard(name: "VistorProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: UserVistorViewController.className) as! UserVistorViewController
            vc.userPublic.onNext(profile)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    func setData(leaderBoards: [LeaderBoard], challenge: Challenge, isFollowTab: Bool = false) {
        print("can get setData: \(isFollowTab)")
        self.isFollowTab = isFollowTab
        self.challenge = challenge
        self.leaderBoards.accept(leaderBoards)
    }
}
