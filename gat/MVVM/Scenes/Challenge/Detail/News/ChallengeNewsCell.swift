//
//  ChallengeNewsCell.swift
//  gat
//
//  Created by Hung Nguyen on 1/29/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class ChallengeNewsCell: UITableViewCell {
    
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var lbContent: UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    
    fileprivate var user: Profile?
    
    fileprivate var cActivity: CActivity?
    
    var showUser: ((UserPublic) -> Void)?
    
    var showBookDetail : ((BookInfo) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.ivAvatar.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            guard let user = self?.user, user.id != User.adminId else { return }
            let userPublic = UserPublic()
            userPublic.profile = user 
            self?.showUser?(userPublic)
        }).disposed(by: self.disposeBag)
        
        self.lbContent.rx.tapGesture().when(.recognized).subscribe(onNext: { (_) in
            guard let act = self.cActivity  else {return}
            if act.typeId == 2 {
                var book = BookInfo()
                book = act.book!
                self.showBookDetail!(book)
            }
            }).disposed(by: disposeBag)
    }
    
//    func eventTapCellUpdate(cActivity: CActivity){
//            self.lbContent
//                .rx
//                .tapGesture()
//                .when(.recognized)
//                .subscribe(onNext: { _ in
//                    if cActivity.typeId == 2 {
//                        self.isTapCellUpdateProgress?(true, cActivity.book?.editionId ?? 1)
//                    }
//                }).disposed(by: disposeBag)
//
//    }
    
    func setData(cActivity: CActivity) {
        self.cActivity = cActivity
        self.user = cActivity.user
        self.ivAvatar.setCircle(imageId: cActivity.user?.imageId ?? "")
        self.lbName.text = cActivity.user?.name ?? ""
        let timeAgo = TimeUtils.getDateFromString(cActivity.createDate)?.getElapsedInterval()
        self.lbTime.text = timeAgo
        
        // Set text content by progress
        switch cActivity.typeId {
        case 1:
            let text = String(format: "ACTIVITY_JUST_JOIN_CHALLENGE".localized(), cActivity.user?.name ?? "", cActivity.challenge?.title ?? "")
            let attribute = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0, green: 0.1417105794, blue: 0.2883770168, alpha: 1)])
            attribute.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: (text as NSString).range(of: cActivity.user?.name ?? ""))
            attribute.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: (text as NSString).range(of: cActivity.challenge?.title ?? ""))
            self.lbContent.attributedText = attribute
        case 2:
            let text = String(format: "ACTIVITY_JUST_UPDATE_CHALLENGE".localized(), cActivity.user?.name ?? "", cActivity.book?.title ?? "")
            let attribute = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0, green: 0.1417105794, blue: 0.2883770168, alpha: 1)])
            attribute.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: (text as NSString).range(of: cActivity.user?.name ?? ""))
            attribute.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)], range: (text as NSString).range(of: cActivity.book?.title ?? ""))
            self.lbContent.attributedText = attribute
        case 4:
            let text = String(format: "ACTIVITY_WRITE_A_POST".localized(), cActivity.user?.name ?? "")
            let attribute = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0, green: 0.1417105794, blue: 0.2883770168, alpha: 1)])
            attribute.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: (text as NSString).range(of: cActivity.user?.name ?? ""))
            self.lbContent.attributedText = attribute
        default:
            self.lbContent.text = ""
        }
//        if let it = cActivity.cProgress {
//            switch it.progress {
//            case 0:
//                self.lbContent.text = String(format: "ACTIVITY_JUST_JOIN_CHALLENGE".localized(), cActivity.user?.name ?? "")
//            case it.targetNumber:
//                self.lbContent.text = String(format: "ACTIVITY_HAS_COMPLETED_CHALLENGE".localized(), cActivity.user?.name ?? "")
//            default:
//                self.lbContent.text = String(format: "ACTIVITY_JUST_UPDATE_CHALLENGE".localized(), cActivity.user?.name ?? "", it.progress, it.targetNumber)
//            }
//        }
        
        
    }
}
