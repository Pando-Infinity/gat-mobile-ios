//
//  CommentTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 12/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import Cosmos
import SDWebImage
import RxGesture
import RxSwift
import RxCocoa

class CommentTableViewCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var hashtagLabel: UILabel!
    
    fileprivate var disposeBag = DisposeBag()
    weak var datasource: DetailCommentDataSource?
    fileprivate var user: Profile?
    let post = BehaviorRelay<Post?>(value: nil)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.setupEvent()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.userImageView.circleCorner()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.userImageView.isUserInteractionEnabled = true
        self.post.compactMap { $0?.creator.profile.imageId }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }
            .bind(to: self.userImageView.rx.url(placeholderImage: DEFAULT_USER_ICON))
            .disposed(by: self.disposeBag)
        self.post.compactMap { $0?.creator.profile.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.rateView.isUserInteractionEnabled = false
        self.post.compactMap { $0?.rating }.bind { [weak self] value in
            self?.rateView.rating = value
        }
        .disposed(by: self.disposeBag)
    
        self.post.compactMap { $0?.date }
            .map({ (date) -> Date in
                if let publishedDate = date.publishedDate {
                    return publishedDate
                } else if let lastUpdate = date.lastUpdate {
                    return lastUpdate
                } else {
                    return Date()
                }
            })
            .map { AppConfig.sharedConfig.calculatorDay(date: $0) }
            .bind(to: self.dateLabel.rx.text)
            .disposed(by: self.disposeBag)
        self.titleLabel.numberOfLines = 2
        self.post.map { $0?.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.post.map { $0?.intro }.bind(to: self.introLabel.rx.text).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.intro.isEmpty }.bind(to: self.introLabel.rx.isHidden).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.hashtags }.map { $0.map { "#\($0.name)" }.joined() }.bind(to: self.hashtagLabel.rx.text).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.hashtags.isEmpty }.bind(to: self.hashtagLabel.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func setupEvent() {
        self.userImageView.rx.tapGesture()
            .when(.recognized)
            .withLatestFrom(self.post.compactMap { $0 })
            .bind { [weak self] post in
                if post.creator.profile.id == Session.shared.user?.id {
                    let storyBoard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                    let vc = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                    vc.isShowButton.onNext(true)
                    self?.datasource?.viewcontroller?.bookDetailController?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let userPublic = UserPublic()
                    userPublic.profile = post.creator.profile
                    self?.datasource?.viewcontroller?.bookDetailController?.performSegue(withIdentifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: userPublic)
                }
            }
            .disposed(by: self.disposeBag)
    }
    
}
