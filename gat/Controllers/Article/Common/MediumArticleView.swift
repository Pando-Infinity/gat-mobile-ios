//
//  MediumArticleView.swift
//  gat
//
//  Created by jujien on 8/18/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MediumArticleView: SmallArticleView {
    
    fileprivate static let USER_CONTAINER_HEIGHT: CGFloat = 52.0
    fileprivate static let SUMMARY_CONTAINER_HEIGHT: CGFloat = 32.0
    fileprivate static let IMAGE_HEIGHT: CGFloat = 123.0
    fileprivate static let RATING_HEIGHT: CGFloat = 14.0
    
    var tapCell:((OpenPostDetail,Bool)->Void)?
    var tapUser:((Bool)-> Void)?
    var tapBook:((Bool)-> Void)?
    let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.event()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.previewImageView.cornerRadius(radius: 0.0)
    }
    
    override class func size(post: Post, estimatedSize: CGSize) -> CGSize {
        let margin: CGFloat = 16.0
        let spacing: CGFloat = 8.0
        let widthContainerText = estimatedSize.width - margin * 2.0
        
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
            let text = "\(book.title)"
            let attributed = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)])
            info.attributedText = attributed
            infoHeight = info.sizeThatFits(.init(width: widthContainerText - 14.0 - spacing / 2.0, height: .infinity)).height
        } else {
            let info = UILabel()
            info.numberOfLines = 2
            info.text = post.categories.first?.title
            info.font = .systemFont(ofSize: 12.0, weight: .semibold)
            infoHeight = info.sizeThatFits(.init(width: widthContainerText - 14.0 - spacing / 2.0, height: .infinity)).height
        }
        
        var height = MediumArticleView.USER_CONTAINER_HEIGHT + MediumArticleView.IMAGE_HEIGHT + spacing + titleHeight + spacing + MediumArticleView.RATING_HEIGHT + spacing + introHeight
        if post.hashtags.isEmpty {
            height += spacing + infoHeight + spacing
        } else {
            height += spacing / 2.0 + hashtagHeight + spacing + infoHeight + spacing
        }
        height += MediumArticleView.SUMMARY_CONTAINER_HEIGHT
        return .init(width: estimatedSize.width, height: height)
    }
    
    
    fileprivate func event(){
        self.tapView()
        self.tapToOpenUser()
        self.tapBookTitle()
    }
    
    fileprivate func tapView(){
        let stackView:[UIView] = [self.previewImageView, self.titleLabel, self.introLabel]
        for i in stackView {
            i.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { (_) in
                    self.tapCell?(OpenPostDetail.OpenNormal,true)
                }).disposed(by: self.disposeBag)
        }
    }
    
    fileprivate func tapToOpenUser(){
        self.userImageView.rx.tapGesture()
        .when(.recognized)
        .subscribe(onNext: { (_) in
            self.tapUser?(true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func tapBookTitle(){
        self.infoBookLabel.rx.tapGesture()
        .when(.recognized)
        .subscribe(onNext: { (_) in
            self.tapBook?(true)
        }).disposed(by: self.disposeBag)
    }
}
