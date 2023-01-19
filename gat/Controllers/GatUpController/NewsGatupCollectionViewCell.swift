//
//  NewsGatupCollectionViewCell.swift
//  gat
//
//  Created by jujien on 12/31/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class NewsGatupCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { return "newsGatupCell" }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var seperateView: UIView!
    @IBOutlet weak var descriptionBottomHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionBottomLowConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    fileprivate let disposeBag = DisposeBag()
    let news: BehaviorRelay<NewsBookstop> = .init(value: .init())
    var showBookstop: ((Bookstop) -> Void)?
    var showBookEdtion: ((BookInfo) -> Void)?
    
    fileprivate let imageGatupView = Bundle.main.loadNibNamed(ImageGatupView.className, owner: self, options: nil)?.first as! ImageGatupView
    fileprivate let bookGatupView = Bundle.main.loadNibNamed(BookGatupView.className, owner: self, options: nil)?.first as! BookGatupView
    fileprivate let bookstopGatupView = Bundle.main.loadNibNamed(BookstopGatupView.className, owner: self, options: nil)?.first as! BookstopGatupView
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageGatupView.removeFromSuperview()
        self.bookGatupView.removeFromSuperview()
        self.bookstopGatupView.removeFromSuperview()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.circleCorner()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80.0
        self.dateLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80.0
        self.setupHeader()
        self.setupContainer()
    }
    
    fileprivate func setupHeader() {
        self.titleLabel.text = Gat.Text.Gatup.GATUP_TITLE.localized()//"GAT-UP Offical"
        self.news.map { AppConfig.sharedConfig.calculatorDay(date: $0.date) }.bind(to: self.dateLabel.rx.text).disposed(by: self.disposeBag)
        self.news.filter { $0.type == .admin }.map { _ in #imageLiteral(resourceName: "gatup") }.bind(to: self.imageView.rx.image).disposed(by: self.disposeBag)
        self.imageView.layer.borderColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1)
        self.imageView.layer.borderWidth = 1.0
        self.news.map { $0.description }.bind(to: self.descriptionLabel.rx.text).disposed(by: self.disposeBag)
        self.news.filter { $0.type == .gatup }
            .map { $0.bookstop?.profile?.imageId }
            .filter { $0 != nil }.map { URL.init(string: AppConfig.sharedConfig.setUrlImage(id: $0!)) }
            .subscribe(onNext: { [weak self] (url) in
                self?.imageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupContainer() {
        self.news.filter { $0.isListImage }.map { $0.lists?.map { "\($0)" } ?? [] }
            .subscribe(onNext: self.setupListImage(imageIds:)).disposed(by: self.disposeBag)
        self.news.filter { $0.isListBook }.map { $0.lists ?? [] }.subscribe(onNext: self.setupListBook(editionIds:)).disposed(by: self.disposeBag)
        self.news.filter { !$0.isListBook && !$0.isListImage && $0.bookstop != nil }
            .map { $0.bookstop! }
            .subscribe(onNext: self.setupBooktop(bookstop:))
            .disposed(by: self.disposeBag)
        self.news.filter { !$0.isListBook && !$0.isListImage && $0.bookstop == nil }
            .subscribe(onNext: { [weak self] (_) in
                self?.descriptionBottomLowConstraint.priority = .defaultHigh
                self?.descriptionBottomHighConstraint.priority = .defaultLow
                self?.containerHeightConstraint.constant = 0.0
                self?.containerView.isHidden = true
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupListImage(imageIds: [String]) {
        self.containerView.isHidden = false
        self.descriptionBottomLowConstraint.priority = .defaultLow
        self.descriptionBottomHighConstraint.priority = .defaultHigh
        if imageIds.count == 1 {
            self.containerHeightConstraint.constant = 314.0
        } else {
            self.containerHeightConstraint.constant = 170.0
        }
        self.layoutIfNeeded()
        self.imageGatupView.frame = self.containerView.bounds
        self.containerView.addSubview(self.imageGatupView)
        self.imageGatupView.imageIds.accept(imageIds)
        if #available(iOS 13.0, *) {
            self.imageGatupView.setupLayout(images: imageIds)
        }
        
    }
    
    fileprivate func setupListBook(editionIds: [Int]) {
        self.containerView.isHidden = false
        self.descriptionBottomLowConstraint.priority = .defaultLow
        self.descriptionBottomHighConstraint.priority = .defaultHigh
        self.containerHeightConstraint.constant = 130.0
        self.layoutIfNeeded()
        self.bookGatupView.frame = self.containerView.bounds
        self.containerView.addSubview(self.bookGatupView)
        self.bookGatupView.editions.accept(editionIds)
        self.bookGatupView.showBookDetail = self.showBookEdtion
    }
    
    fileprivate func setupBooktop(bookstop: Bookstop) {
        self.containerView.isHidden = false
        self.descriptionBottomLowConstraint.priority = .defaultLow
        self.descriptionBottomHighConstraint.priority = .defaultHigh
        let size = BookstopGatupView.size(bookstop: bookstop)
        self.containerHeightConstraint.constant = size.height
        self.layoutIfNeeded()
        self.bookstopGatupView.frame = self.containerView.bounds
        self.containerView.addSubview(self.bookstopGatupView)
        self.bookstopGatupView.bookstop.accept(bookstop)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.imageView.isUserInteractionEnabled = true
        Observable.of(
            self.imageView.rx.tapGesture().when(.recognized),
            self.bookstopGatupView.rx.tapGesture().when(.recognized)
        )
            .merge()
        .subscribe(onNext: { [weak self] (_) in
            guard let bookstop = self?.news.value.bookstop else { return }
            self?.showBookstop?(bookstop)
        }).disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {} else {
            var height: CGFloat = 72.0 + self.descriptionLabel.sizeThatFits(.init(width: UIScreen.main.bounds.width - 32.0, height: .infinity)).height + self.containerHeightConstraint.constant + 16.0
            if self.news.value.isListBook || self.news.value.isListImage || self.news.value.bookstop != nil {
                height += 16.0
            }
            attributes.frame.size = .init(width: UIScreen.main.bounds.width, height: height)
        }
        return attributes
    }
}

extension NewsGatupCollectionViewCell {
    class func size(news: NewsBookstop, in collectionView: UICollectionView) -> CGSize {
        let width = collectionView.frame.width
        var height: CGFloat = 72.0
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0)
        label.numberOfLines = 0
        label.text = news.description
        let size = label.sizeThatFits(.init(width: width - 32.0, height: .infinity))
        height += 16.0 + size.height
        if news.isListBook {
            height += 130.0 + 16.0
        } else if news.isListImage {
            if news.lists!.count == 1 {
                height += 314.0 + 16.0
            } else {
                height += 80.0 + 16.0
            }
        } else if news.bookstop != nil {
            height += BookstopGatupView.size(bookstop: news.bookstop!).height + 16.0
        }
        return .init(width: width, height: height)
    }
}
