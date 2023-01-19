//
//  ChallengeCell.swift
//  gat
//
//  Created by Frank Nguyen on 1/9/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class ChallengeCell: UITableViewCell {
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var vItemChallenge: UIView!
    @IBOutlet weak var ivCover: UIImageView!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbNumUser: UILabel!
    @IBOutlet weak var lbTime: UILabel!
    
    private var challenge: Challenge?
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setData(_ challenge: Challenge) {
        self.challenge = challenge
        print("set data title: \(challenge.title)")
        ivCover.setImage(imageId: challenge.imageCover)
        lbTitle.text = challenge.title
        lbNumUser.text = String(format: "NUMBER_MEM_CHALLENGE".localized(), challenge.challengeSummary?.totalJoiner ?? 0)
        lbTime.text = TimeUtils.getTimeDuration(challenge.startDate, challenge.endDate)//TimeUtils.convertUtcToDmy(challenge.startDate)
    }
    
    private func setOnItemClicked() {
        print("setOnItemClicked called")
        self.vItemChallenge.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                if let it = self.challenge {
                    print("setOnItemClicked send event called")
                    SwiftEventBus.post(
                        OpenChallengeDetailEvent.EVENT_NAME,
                        sender: OpenChallengeDetailEvent(it.id)
                    )
                }
            })
        .disposed(by: disposeBag)
    }
}
