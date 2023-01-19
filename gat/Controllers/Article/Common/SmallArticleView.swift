//
//  SmallArticleView.swift
//  gat
//
//  Created by jujien on 8/10/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Cosmos

class SmallArticleView: UIView {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var optionButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var hashtagLabel: UILabel!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var infoBookLabel: UILabel!
    @IBOutlet weak var numberHeartLabel: UILabel!
    @IBOutlet weak var numberCommentLabel: UILabel!
    @IBOutlet weak var infoTopHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoTopLowConstraint: NSLayoutConstraint!
    
    var viewContent = UIView()
    
    @IBOutlet weak var bookImageView: UIImageView!
    fileprivate let disposeBag = DisposeBag()
    
    let post: BehaviorRelay<Post?> = .init(value: nil)
    var showUser: ((Profile) -> Void)? = nil
    var showOption: ((Post,Bool) -> Void)? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
        self.viewContent.backgroundColor = .clear
        self.addSubview(self.viewContent)
        self.sendSubviewToBack(self.viewContent)
        viewContent.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: viewContent, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: viewContent, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: viewContent, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: viewContent, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.userImageView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.userImageView.circleCorner()
        self.previewImageView.cornerRadius(radius: 10.0)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.numberOfLines = 2
        self.infoBookLabel.numberOfLines = 1
        self.ratingView.settings.filledImage = UIImage(named: "filledStar")
        self.ratingView.settings.emptyImage = UIImage(named: "emptyStar")
        self.ratingView.settings.starMargin = 1.0
        self.ratingView.isUserInteractionEnabled = false
        self.post.compactMap { $0?.creator.profile.imageId }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }
            .bind(to: self.userImageView.rx.url(placeholderImage: DEFAULT_USER_ICON))
            .disposed(by: self.disposeBag)
        self.post.map { $0?.creator.profile.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.date }.map { (date) -> Date? in
            let time = date.lastUpdate ?? date.publishedDate
            return time
        }.compactMap { $0 }
            .map({ (time) -> String in
                let stringTime = AppConfig.sharedConfig.calculatorDay(date: time)
                return stringTime
            })
            .bind(to: self.dateLabel.rx.text).disposed(by: self.disposeBag)
        self.post.map { $0?.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.rating }.withLatestFrom(Observable.just(self.ratingView).compactMap { $0 }, resultSelector: { ($0, $1) })
            .subscribe(onNext: { (value, ratingView) in
                ratingView.rating = value
            }).disposed(by: self.disposeBag)
        
        self.post.compactMap { $0?.isReview }.map { !$0 }.bind(to: self.ratingView.rx.isHidden).disposed(by: self.disposeBag)
        
        self.post.map { $0?.intro }.bind(to: self.introLabel.rx.text).disposed(by: self.disposeBag)
        
        self.post.compactMap { $0?.hashtags }.map { $0.isEmpty }.bind(to: self.hashtagLabel.rx.isHidden).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.hashtags.first.map { $0.name } }.map { "#\($0)" }.bind(to: self.hashtagLabel.rx.text).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.hashtags }.map { $0.isEmpty }.withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
            .subscribe(onNext: { (isEmpty, cell) in
                cell.layoutIfNeeded()
                cell.infoTopHighConstraint.priority = isEmpty ? .defaultLow : .defaultHigh
                cell.infoTopLowConstraint.priority = isEmpty ? .defaultHigh : .defaultLow
                cell.layoutIfNeeded()
            })
            .disposed(by: self.disposeBag)
        
        self.bookImageView.tintColor = .fadedBlue
        self.post.compactMap { $0?.isReview }.map { (value) -> UIImage in
            if value {
                return #imageLiteral(resourceName: "hardboundBookVariant")
            } else {
                let image = #imageLiteral(resourceName: "combinedShapeCopy").withRenderingMode(.alwaysTemplate)
                return image
            }
        }
        .bind(to: self.bookImageView.rx.image)
        .disposed(by: self.disposeBag)
        

        self.post.compactMap { $0 }.filter { !$0.isReview }.map { (post) -> NSAttributedString in
            return .init(string: post.categories.first?.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue])
        }
        .bind(to: self.infoBookLabel.rx.attributedText)
        .disposed(by: self.disposeBag)
        
        self.post.compactMap { $0 }.filter { $0.isReview }.compactMap { $0.editionTags.first }.map { (book) -> NSMutableAttributedString in
            let text = "\(book.title)"
            let attributed = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 12.0, weight: .semibold), .foregroundColor: UIColor.fadedBlue])
            return attributed
        }
        .bind(to: self.infoBookLabel.rx.attributedText)
        .disposed(by: self.disposeBag)
//
        self.post.compactMap { $0?.summary.reactCount }.map { "\($0)" }.bind(to: self.numberHeartLabel.rx.text).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.summary.commentCount }.map { String(format:"NUMBER_COMMENT_POST_TITLE".localized(),$0) }.bind(to: self.numberCommentLabel.rx.text).disposed(by: self.disposeBag)
        self.post.compactMap { $0?.postImage.thumbnailId }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }.bind(to: self.previewImageView.rx.url(placeholderImage: UIImage(named: "article_default_\(Int.random(in: 1...10))")!)).disposed(by: self.disposeBag)
        self.previewImageView.contentMode = .scaleAspectFill
        
    }
    
    func hideMoreOption(hide: Bool){
        self.optionButton.isHidden = hide
    }
    
    func hideHeader(hide: Bool){
        self.nameLabel.isHidden = hide
        self.dateLabel.isHidden = hide
        self.userImageView.isHidden = hide
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.userEvent()
        self.optionEvent()
    }
    
    fileprivate func userEvent() {
        self.userImageView.isUserInteractionEnabled = true
        self.userImageView.rx.tapGesture().when(.recognized)
            .withLatestFrom(self.post.asObservable())
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] (post) in
                self?.showUser?(post.creator.profile)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func optionEvent() {
        guard self.optionButton != nil else { return }
        self.optionButton.rx.tap
            .withLatestFrom(self.post.asObservable()).compactMap { $0 }
            .subscribe(onNext: { [weak self] (post) in
                self?.showOption?(post,true)
            })
            .disposed(by: self.disposeBag)
    }
    
    class func size(post: Post, estimatedSize: CGSize) -> CGSize {
        let margin: CGFloat = 16.0
        let spacing: CGFloat = 8.0
        let widthImage = estimatedSize.width * 0.25
        let widthContainerText = estimatedSize.width - margin - spacing - widthImage - margin
        
        let title = UILabel()
        title.text = post.title
        title.numberOfLines = 3
        title.font = .systemFont(ofSize: 16.0, weight: .semibold)
        
        let titleHeight = title.sizeThatFits(.init(width: widthContainerText, height: .infinity)).height
        let intro = UILabel()
        intro.text = post.intro
        intro.numberOfLines = 2
        intro.font = .systemFont(ofSize: 12.0)
        let introHeight = intro.sizeThatFits(.init(width: widthContainerText, height: .infinity)).height
        
        var hashtagHeight: CGFloat = 0.0
        if !post.hashtags.isEmpty {
            let hashtag = UILabel()
            hashtag.text = post.hashtags.map { $0.name }.joined(separator: "#")
            hashtag.numberOfLines = 0
            hashtag.font = .systemFont(ofSize: 12.0)
            hashtagHeight = hashtag.sizeThatFits(.init(width: widthContainerText, height: .infinity)).height
        }
        
        var infoHeight: CGFloat = .zero
        if let book = post.editionTags.first, post.isReview {
            let info = UILabel()
            info.numberOfLines = 2
            let text = "\(book.title)"
            let attributed = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)])
            info.attributedText = attributed
            infoHeight = info.sizeThatFits(.init(width: widthContainerText - 14.0 - spacing / 2.0, height: .infinity)).height
        } else {
            let info = UILabel()
            info.numberOfLines = 2
            info.text = post.categories.first?.title
            info.font = .systemFont(ofSize: 14.0, weight: .semibold)
            infoHeight = info.sizeThatFits(.init(width: widthContainerText - 14.0 - spacing / 2.0, height: .infinity)).height
        }
        
        
        var height = SmallArticleView.USER_CONTAINER_HEIGHT + titleHeight + spacing + SmallArticleView.RATING_HEIGHT + spacing + introHeight
        if post.hashtags.isEmpty {
            height += spacing + infoHeight + spacing
        } else {
            height += spacing / 2.0 + hashtagHeight + spacing + infoHeight + spacing
        }
        height += SmallArticleView.SUMMARY_CONTAINER_HEIGHT
        return CGSize(width: estimatedSize.width, height: height > estimatedSize.height ? height : estimatedSize.height)
    }
    
}

extension SmallArticleView {
    
    fileprivate static let USER_CONTAINER_HEIGHT: CGFloat = 64.0
    fileprivate static let SUMMARY_CONTAINER_HEIGHT: CGFloat = 38.0
    fileprivate static let RATING_HEIGHT: CGFloat = 14.0
    
    
}

extension Array where Self.Element == String {
    func addCharacter(adding:String)->String{
        var text = self.joined(separator: adding)
        text = adding + text
        return text
    }
}
