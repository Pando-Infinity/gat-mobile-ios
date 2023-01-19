//
//  SummayPostCollectionViewCell.swift
//  gat
//
//  Created by jujien on 5/6/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SummayPostCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "summayPostCell" }
    
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var numberHeartLabel: UILabel!
    @IBOutlet weak var numberCommentLabel: UILabel!
//    @IBOutlet weak var numberSharing: UILabel!
    
    
    var openListReaction: (() -> Void)?
    let summary: BehaviorRelay<PostSummary?> = .init(value: nil)
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.summary.compactMap { $0 }.map { String(format:"NUMBER_REACTION_POST_TITLE".localized(),$0.reactCount) }.bind(to: self.numberHeartLabel.rx.text).disposed(by: self.disposeBag)
        self.summary.compactMap { $0 }.map { String(format:"NUMBER_COMMENT_POST_TITLE".localized(), $0.commentCount) }.bind(to: self.numberCommentLabel.rx.text).disposed(by: self.disposeBag)
//        self.summary.compactMap { $0 }.map { "\($0.shareCount) chia sẻ" }.bind(to: self.numberSharing.rx.text).disposed(by: self.disposeBag)
        self.event()
    }
    
    fileprivate func event() {
        Observable.of(
            self.heartButton.rx.tap.asObservable(),
            self.numberHeartLabel.rx.tapGesture().when(.recognized).map { _ in }
        )
        .merge()
        .subscribe { [weak self] (_) in
            self?.openListReaction?()
        }
        .disposed(by: self.disposeBag)

    }

}

extension SummayPostCollectionViewCell {
    class func size(in bounds: CGSize) -> CGSize { .init(width: bounds.width, height: 48.0) }
}
