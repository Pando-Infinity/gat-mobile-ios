//
//  MyChallengeCell.swift
//  gat
//
//  Created by Hung Nguyen on 1/11/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol MyChallengeCellDelegate {
    func didTapUpdateChallenge()
}

class MyChallengeCell: UICollectionViewCell {
    
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbTarget: UILabel!
    @IBOutlet weak var lbTimeRemain: UILabel!
    @IBOutlet weak var lbPercent: UILabel!
    @IBOutlet weak var vProgress: UIProgressView!
    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var completeLabel: UILabel!
    
    var delegate: MyChallengeCellDelegate?
    
    var sizeCell: CGSize = .zero
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set localiuze
//        btnUpdate.setTitle("BUTTON_UPDATE_STATUS".localized(), for: .normal)
        self.vProgress.progressViewStyle = .bar
    }
    
    func setData(challenge: Challenge) {
        lbTitle.text = challenge.title
        //        lbTarget.text = challenge.description
        var text = ""
        var attribute: NSMutableAttributedString!
        if challenge.challengeModeId == 1 {
            text = String(format: "\("INDIVIDUAL_CHALLENGE_TITLE".localized()): \("INDIVIDUAL_CHALLENGE".localized())", challenge.challengeProgress?.targetNumber ?? 0)//"Cá nhân: đọc \(challenge.challengeProgress?.targetNumber ?? 0) quyển sách"
            attribute = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0, green: 0.1417105794, blue: 0.2883770168, alpha: 1)])
            attribute.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: (text as NSString).range(of: "\("INDIVIDUAL_CHALLENGE_TITLE".localized()):"))
            
            self.completeLabel.text = String(format: "PROGRESS_READ_BOOK_MESSAGE".localized(), challenge.challengeProgress?.progress ?? 0)
        } else {
            text = String(format: "\("GROUP_CHALLENGE_TITLE".localized()): \("GROUP_CHALLENGE".localized())", challenge.challengeProgress?.targetNumber ?? 0)
            attribute = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0, green: 0.1417105794, blue: 0.2883770168, alpha: 1)])
            attribute.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: (text as NSString).range(of: "\("GROUP_CHALLENGE_TITLE".localized()):"))
            
            self.completeLabel.text = String(format: "PROGRESS_READ_BOOK_MESSAGE".localized(), challenge.challengeSummary?.totalObject ?? 0)
            print("TO: \(challenge.challengeSummary?.totalObject ?? 0)")
        }
        //"Đã hoàn thành \(challenge.challengeProgress?.progress ?? 0) quyển"
        self.progressLabel.attributedText = attribute
        
        lbTimeRemain.text = String(
            format: "REMAINING_TIME".localized(),
            TimeUtils.getTimeRemain(challenge.endDate)
        )
        
        // calculate progress of challenge
        if challenge.challengeModeId == 1 {
            if let progress = challenge.challengeProgress {
                var percent = Double(progress.progress) / Double(progress.targetNumber)
                print("percent: \(percent)")
                if percent > 1.0 {
                    percent = 1.0
                }
                vProgress.progress = Float(percent)
                let percent100 = Int(percent * 100)
                lbPercent.text = "\(percent100)%"
                if AppConfig.sharedConfig.convertToDate(from: challenge.endDate, format: "yyyy-MM-dd'T'HH:mm:ss.SSZ").timeIntervalSince1970 < Date().timeIntervalSince1970 {
                    self.lbTimeRemain.text = percent == 1.0 ? "COMPLETED_CHALENGE".localized() : "EXPIRED_CHALLENGE".localized()
                    //                self.btnUpdate.isHidden = true
                } else {
                    //                self.btnUpdate.isHidden = false
                }
            }
        } else {
            if let totalObj = challenge.challengeSummary, let progress = challenge.challengeProgress {
                var percent = Double(totalObj.totalObject) / Double(progress.targetNumber)
                print("percent: \(percent)")
                if percent > 1.0 {
                    percent = 1.0
                }
                vProgress.progress = Float(percent)
                let percent100 = Int(percent * 100)
                lbPercent.text = "\(percent100)%"
                if AppConfig.sharedConfig.convertToDate(from: challenge.endDate, format: "yyyy-MM-dd'T'HH:mm:ss.SSZ").timeIntervalSince1970 < Date().timeIntervalSince1970 {
                    self.lbTimeRemain.text = percent == 1.0 ? "COMPLETED_CHALENGE".localized() : "EXPIRED_CHALLENGE".localized()
                    //                self.btnUpdate.isHidden = true
                } else {
                    //                self.btnUpdate.isHidden = false
                }
            }
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.cornerRadius(radius: 8.0)
        self.vProgress.cornerRadius(radius: self.vProgress.frame.height / 2.0)
        self.vProgress.subviews.forEach { $0.cornerRadius(radius: $0.frame.height / 2.0) }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell != .zero {
            layout.frame.size = self.sizeCell
        }
        return layout
    }
    
    @IBAction func onUpdate(_ sender: Any) {
        print("MyChallengeCell onUpdate")
        SwiftEventBus.post(OpenReadingsEvent.EVENT_NAME)
    }
}
