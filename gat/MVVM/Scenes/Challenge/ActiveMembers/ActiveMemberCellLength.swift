//
//  ActiveMemberCellLength.swift
//  gat
//
//  Created by Hung Nguyen on 1/28/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class ActiveMemberCellLength: UITableViewCell {
    
    @IBOutlet weak var ivStar: UIImageView!
    @IBOutlet weak var lbRank: UILabel!
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var ivCheck: UIImageView!
    @IBOutlet weak var lbProgress: UILabel!
    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var ivFollow: UIImageView!
    @IBOutlet weak var lbFollow: UILabel!
    @IBOutlet weak var stackFollow: UIStackView!
    
    @IBOutlet weak var constraitShort: NSLayoutConstraint!
    @IBOutlet weak var constraintLong: NSLayoutConstraint!
    
    @IBOutlet weak var constraintShortAvatar: NSLayoutConstraint!
    @IBOutlet weak var constraintLongAvatar: NSLayoutConstraint!
    
    @IBOutlet weak var constraintLongBtnUpdate: NSLayoutConstraint!
    @IBOutlet weak var constraintShortBtnUpdate: NSLayoutConstraint!
    
    fileprivate var disposeBag = DisposeBag()
    fileprivate var leaderBoard: LeaderBoard?
    var showUser: ((UserPublic) -> Void)?
    var updateFollow: ((LeaderBoard, Bool) -> Void)?
    
    @IBAction func onUpdate(_ sender: Any) {
        SwiftEventBus.post(ActiveMemberUpdateReadingEvent.EVENT_NAME)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.ivAvatar.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            guard let user = self?.leaderBoard?.user, user.id != User.adminId else { return }
            let userPublic = UserPublic()
            userPublic.profile.id = user.id
            userPublic.profile.name = user.name
            userPublic.profile.imageId = user.imageId
            self?.showUser?(userPublic)
        }).disposed(by: self.disposeBag)
        self.setOnFollowTapped()
    }
    
    func setData(_ leaderBoard: LeaderBoard, _ challenge: Challenge, _ position: Int, _ isFollowingTab: Bool = false) {
        self.leaderBoard = leaderBoard
        self.btnUpdate.setTitle("UPDATE_PROGRESS".localized(), for: .normal)
        
        if isFollowingTab {
            self.ivStar.visiblity(gone: true, dimension: 0, attribute: .width)
            self.lbRank.visiblity(gone: true, dimension: 0, attribute: .width)
            self.constraintLongAvatar.priority = .defaultHigh
            self.constraintShortAvatar.priority = .defaultLow
            self.stackFollow.isHidden = Session.shared.isAuthenticated
        }
        
        // Set image Star by rank
        switch position {
            case 0:
                self.ivStar.isHidden = false
                self.ivStar.image = UIImage(named: "ic_star_yellow")
            case 1:
                self.ivStar.isHidden = false
                self.ivStar.image = UIImage(named: "ic_star_green")
            case 2:
                self.ivStar.isHidden = false
                self.ivStar.image = UIImage(named: "ic_star_brown")
            default:
                self.ivStar.isHidden = true
        }
        
        if position < 3 {
            self.lbRank.textColor = .white
        } else {
            self.lbRank.textColor = .gray
        }
        
        print("name: \(leaderBoard.user?.name), isFollowing: \(leaderBoard.isFollowing), type: \(isFollowingTab)")
        if leaderBoard.isFollowing {
            self.ivFollow.image = UIImage(named: "ic_followed_blue")
            self.lbFollow.text = "FOLLOWED".localized()
            self.lbFollow.textColor = Colors.blueDark
        } else {
            self.ivFollow.image = UIImage(named: "ic_follow_gray")
            self.lbFollow.text = "FOLLOW".localized()
            self.lbFollow.textColor = .gray
        }
        if Session.shared.isAuthenticated {
            self.stackFollow.isHidden = leaderBoard.user?.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id
        } else {
            self.stackFollow.isHidden = true
        }
        
        self.lbRank.text = "\(position + 1)"
        self.lbRank.sizeToFit()
        self.ivAvatar.setCircle(imageId: leaderBoard.user?.imageId ?? "")
        self.lbName.text = leaderBoard.user?.name ?? ""
        if challenge.challengeModeId == 1 {
            self.lbProgress.text = String(format: "FORMAT_BOOK_HAS_BEEN_REAEDED".localized(), "\(leaderBoard.progress)/\(leaderBoard.targetNumber)")
        } else {
            self.lbProgress.text = String(format: "FORMAT_BOOK_HAS_BEEN_REAEDED".localized(), "\(leaderBoard.progress)")
        }
        
        
        // Show blue tick when read done
        if leaderBoard.progress >= 0 && leaderBoard.progress >= leaderBoard.targetNumber {
            self.ivCheck.isHidden = false
            self.lbProgress.textColor = Colors.blueDark
        } else {
            self.ivCheck.isHidden = true
            self.lbProgress.textColor = .gray
        }
        
        guard let userId = leaderBoard.user?.id else { return }
//        guard let userInfo = Repository<UserPrivate, UserPrivateObject>.shared.get() else { return }
        
//        print("USER ID: \(userInfo.id), guest: \(userId)")
        if Repository<UserPrivate, UserPrivateObject>.shared.get()?.id == userId {
            self.btnUpdate.visiblity(gone: false, dimension: 143, attribute: .width)
            self.constraitShort.priority = .defaultHigh
            self.constraintLong.priority = .defaultLow

            //self.constraintLongAvatar.priority = .defaultHigh
            self.constraintShortAvatar.priority = .defaultHigh
            //self.stackFollow.visiblity(gone: true, dimension: 0, attribute: .width)
            self.stackFollow.isHidden = true
            self.constraintLongBtnUpdate.priority = .defaultHigh
            self.constraintShortBtnUpdate.priority = .defaultLow
        } else {
            self.btnUpdate.visiblity(gone: true, dimension: 0, attribute: .width)
            self.constraitShort.priority = .defaultLow
            self.constraintLong.priority = .defaultHigh
        }
    }
    
    private func setOnFollowTapped() {
        self.ivFollow.rx.tapGesture()
            .when(.recognized)
            .filter { _ in Session.shared.isAuthenticated }
            .subscribe(onNext: { _ in
                if let it = self.leaderBoard {
                    SwiftEventBus.post(
                        FollowMemberEvent.EVENT_NAME,
                        sender: FollowMemberEvent(
                            it.user?.id ?? 0,
                            it.user?.name ?? "",
                            it.isFollowing
                        )
                    )
                }
            })
        .disposed(by: disposeBag)
    }
}
