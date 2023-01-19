//
//  ActiveMemberCollectionCell.swift
//  gat
//
//  Created by Frank Nguyen on 4/15/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class ActiveMemberCollectionCell: UITableViewCell {
    
    private var disposeBag = DisposeBag()
    
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var btnSeeAll: UIButton!
    @IBOutlet weak var clActiveMember: UICollectionView!
    
    var showUser: ((UserPublic) -> Void)?
    private var activeMembers: [LeaderBoard] = []
    
    var estimateWidth = 80.0
    var cellMarginSize = 4.0
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func initActiveMembers() {
        // Set localize
        self.lbTitle.text = "ACTIVE_MEMBER".localized()
        self.btnSeeAll.setTitle("BUTTON_SEE_ALL".localized(), for: .normal)
        
        // Set delegate
        self.clActiveMember.delegate = self
        self.clActiveMember.dataSource = self
        // Register cells
        self.clActiveMember.register(UINib(nibName: "ActiveMemberCell", bundle: nil), forCellWithReuseIdentifier: "ActiveMemberCell")
        // Setup GridView
        let flow = clActiveMember?.collectionViewLayout as! UICollectionViewFlowLayout
        flow.minimumInteritemSpacing = CGFloat(self.cellMarginSize)
        flow.minimumLineSpacing = CGFloat(self.cellMarginSize)
    }
    
    func setActiveMembers(leaderBoards: [LeaderBoard]) {
        self.activeMembers = Array(leaderBoards.prefix(4))
        self.clActiveMember.reloadData()
    }
    
    @IBAction func onSeeAll(_ sender: Any) {
        SwiftEventBus.post(OpenChallengeMembersEvent.EVENT_NAME)
    }
}

extension ActiveMemberCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activeMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ActiveMemberCell", for: indexPath) as! ActiveMemberCell
        if self.activeMembers.count > indexPath.row {
            cell.setData(self.activeMembers[indexPath.row], indexPath.row)
        }
        
        return cell
    }
}

extension ActiveMemberCollectionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.calculateWidth()
        return CGSize(width: width, height: self.clActiveMember.frame.size.height)
    }
    
    func calculateWidth() -> CGFloat {
        let estimatedWidth = CGFloat(estimateWidth)
        let cellCount = floor(CGFloat(self.clActiveMember.frame.size.width / estimatedWidth))
        
        let margin = CGFloat(cellMarginSize * 2)
        let width = (self.clActiveMember.frame.width - CGFloat(cellMarginSize) * (cellCount - 1) - margin) / cellCount
        
        return width
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let member = self.activeMembers[indexPath.row].user, member.id != User.adminId else { return }
        let userPublic = UserPublic()
        userPublic.profile.id = member.id
        userPublic.profile.name = member.name
        userPublic.profile.imageId = member.imageId
        self.showUser?(userPublic)
    }
}

