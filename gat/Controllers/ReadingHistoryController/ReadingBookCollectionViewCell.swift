//
//  ReadingBookCollectionViewCell.swift
//  gat
//
//  Created by jujien on 1/9/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import GradientProgressBar

class ReadingBookCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { return "readingBookCell" }
    
    @IBOutlet weak var vCell: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var lastDateLabel: UILabel!
    @IBOutlet weak var forwardImageView: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressBar: GradientProgressBar!
    @IBOutlet weak var progressWidthConstraint: NSLayoutConstraint!
    
    let readingBook = BehaviorRelay<Reading>(value: Reading())
    let sizeCell = BehaviorRelay<CGSize>(value: .zero)
    fileprivate var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        
        // Set on Click listener
        self.setOnTapPprogress()
        self.setOnTapCell()
    }
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        disposeBag = DisposeBag()
//    }
    
    fileprivate func setupUI() {
        self.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
        self.forwardImageView.tintColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        self.imageView.cornerRadius(radius: 4.0)
        Observable.combineLatest(self.sizeCell.asObservable(), Observable.just(self.imageView.frame), Observable.just(self.progressWidthConstraint.multiplier), Observable.just(self.forwardImageView.image!.size))
            .map { (sizeCell, imageFrame, multiplier, forwardSize) -> CGFloat in
                let value: CGFloat = 64.0
                return sizeCell.width - imageFrame.width - sizeCell.width * multiplier - forwardSize.width - value
        }
        .subscribe(onNext: { [weak self] (value) in
            self?.titleLabel.preferredMaxLayoutWidth = value
            self?.authorLabel.preferredMaxLayoutWidth = value
        }).disposed(by: self.disposeBag)
        self.setupProgressBar()
        self.readingBook.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0.edition?.imageId ?? "")) }
            .subscribe(onNext: { [weak self] (url) in
                self?.imageView.sd_setImage(with: url, placeholderImage: DEFAULT_BOOK_ICON)
            }).disposed(by: self.disposeBag)
        self.readingBook.map { $0.edition?.title ?? "" }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.readingBook.map { $0.edition?.author ?? "" }.bind(to: self.authorLabel.rx.text).disposed(by: self.disposeBag)
//        self.readingBook.map { $0.startDate == nil }.bind(to: self.lastDateLabel.rx.isHidden).disposed(by: self.disposeBag)
//        self.readingBook.filter { $0.startDate != nil }.map { $0.startDate }.map { "Đọc từ \(AppConfig.sharedConfig.calculatorDay(date: $0.completeDate)) trước" }.bind(to: self.lastDateLabel.rx.text).disposed(by: self.disposeBag)
        
        self.readingBook.map { $0.startDate }.bind { [weak self] (startDate) in
            let date = TimeUtils.getDateFromString(startDate)
            if let it = date {
                self?.lastDateLabel.text = String(format: "FORMAT_READ_FROM_TIME_AGO".localized(), AppConfig.sharedConfig.calculatorDay(date: it))
            }
        }.disposed(by: self.disposeBag)
        self.readingBook.map { "\($0.readPage)/\($0.pageNum)" }.bind(to: self.progressLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupProgressBar() {
        self.progressBar.gradientColors = [#colorLiteral(red: 0.3058823529, green: 0.7019607843, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.5254901961, green: 0.6509803922, blue: 0.8549019608, alpha: 1)]
        self.progressBar.backgroundColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        self.progressBar.cornerRadius(radius: 12.0)
        self.progressBar.layer.borderColor = #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 0.19)
        self.progressBar.layer.borderWidth = 1.0
        
        //self.progressBar.progress = 0.8
        self.readingBook.map { $0.progress }.bind { [weak self] (progress) in
            self?.progressBar.progress = progress
        }.disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell.value != .zero {
            attributes.frame.size = self.sizeCell.value
        }
        return attributes
    }
    
    private func setOnTapPprogress() {
    }
    
    private func setOnTapCell() {
        self.imageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                print("click to cell item")
                guard let it = self.readingBook.value.edition else {return}
                
                var bookInfo = BookInfo()
                bookInfo.editionId = it.editionId
                bookInfo.bookId = it.bookId
                SwiftEventBus.post(
                    OpenBookDetailEvent.EVENT_NAME,
                    sender: OpenBookDetailEvent(bookInfo)
                )
            })
        .disposed(by: disposeBag)
    }
}
