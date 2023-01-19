//
//  HistortReadingBookTableViewCell.swift
//  gat
//
//  Created by jujien on 2/1/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import GradientProgressBar

class HistoryReadingBookTableViewCell: UITableViewCell {
    
    class var identifier: String { return "historyReadingBookCell" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var readingButton: UIButton!
    @IBOutlet weak var progressBar: GradientProgressBar!
    @IBOutlet weak var forwardImageView: UIImageView!
    @IBOutlet weak var currentPageLabel: UILabel!
    @IBOutlet weak var readingBottomHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var readingBottomLowConstraint: NSLayoutConstraint!
    
    let reading = BehaviorRelay<ReadingBook?>(value: nil)
    let numberReadingBook = BehaviorRelay<Int>(value: 0)
    var show: ((AlertAddBookReadingViewController) -> Void)? = nil
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        let readingAvailable = self.reading.map { $0 != nil }.share()
//        Observable.of(
//            Observable.combineLatest(self.numberReadingBook.asObservable(), readingAvailable.filter { !$0 })
//            .map { "\($0.0) bạn đang đọc cuốn sách này" },
//            readingAvailable.filter { $0 }.map { tata in
//                print("tata: \(tata)")
//                return "Đang đọc" }
//            ).merge()
//            .bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        
        self.numberReadingBook.compactMap { $0 }
        .map {
            String(format: "PEOPLE_READ_THIS_BOOK".localized(), $0)
        }
        .bind(to: self.titleLabel.rx.text)
        .disposed(by: self.disposeBag)
        
        self.reading.compactMap { $0 }.filter { $0.status != .none }
            .map {
                if $0.status == .reading {
                    return "READING_STATUS".localized()
                } else {
                    return "READING_FINNISH_STATUS".localized()
                }
            }
            .bind(to: self.titleLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        readingAvailable.bind(to: self.readingButton.rx.isHidden).disposed(by: self.disposeBag)
        
        //self.reading.compactMap { $0 }.map { $0.status == .none || $0.status == .reading }.bind(to: self.progressBar.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
        
        let isHidden = readingAvailable.map { !$0 }
        isHidden.bind(to: self.descriptionLabel.rx.isHidden).disposed(by: self.disposeBag)
        isHidden.bind(to: self.currentPageLabel.rx.isHidden).disposed(by: self.disposeBag)
        isHidden.bind(to: self.progressBar.rx.isHidden).disposed(by: self.disposeBag)
        isHidden.bind(to: self.forwardImageView.rx.isHidden).disposed(by: self.disposeBag)
        self.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
        self.forwardImageView.tintColor = #colorLiteral(red: 0.463742733, green: 0.7132268548, blue: 0.8215666413, alpha: 1)
        self.progressBar.backgroundColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        self.progressBar.gradientColors = [#colorLiteral(red: 0.2862745098, green: 0.7019607843, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.5254901961, green: 0.6509803922, blue: 0.8549019608, alpha: 1)]
        self.progressBar.layer.borderColor = #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 0.19)
        self.progressBar.layer.borderWidth = 1.0
        self.reading.filter { $0 != nil }.map { "\($0!.currentPage)/\($0!.pageNum)" }.bind(to: self.currentPageLabel.rx.text).disposed(by: self.disposeBag)
        self.reading.filter { $0 != nil }.map { $0!.progress }.subscribe(onNext: { [weak self] (value) in
            self?.progressBar.progress = value
        }).disposed(by: self.disposeBag)
        
//        self.reading.filter { $0 != nil }.map {
//                "Bạn bắt đầu đọc từ \(AppConfig.sharedConfig.stringFormatter(from: $0!.startDate ?? Date()))"
//
//            }.bind(to: self.descriptionLabel.rx.text)
//            .disposed(by: self.disposeBag)
        
        self.reading.compactMap { $0 }.map {
            if $0.status == .reading {
                return String(format: "READING_START_DATE".localized(), AppConfig.sharedConfig.stringFormatter(from: $0.startDate ?? Date(), format: LanguageHelper.language == .japanese ? "yyyy-MM-dd" : "yyyy-MM-dd"))
            } else {
                return String(format: "READING_FINNISH_DATE".localized(), AppConfig.sharedConfig.stringFormatter(from: $0.startDate ?? Date(), format: LanguageHelper.language == .japanese ? "yyyy-MM-dd" : "yyyy-MM-dd"))
            }
            
        
        }.bind(to: self.descriptionLabel.rx.text)
        .disposed(by: self.disposeBag)
        
        self.progressBar.cornerRadius(radius: 15.0)
        self.readingButton.setTitle("START_READ_BOOK".localized(), for: .normal)
        
        readingAvailable.subscribe(onNext: { [weak self] (status) in
            self?.readingBottomHighConstraint.priority = status ? .defaultHigh : .defaultLow
            self?.readingBottomLowConstraint.priority = status ? .defaultLow : .defaultHigh
        }).disposed(by: self.disposeBag)
        self.reading.subscribe(onNext: { [weak self] (_) in
            self?.titleLabel.sizeToFit()
        }).disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.readingButton.rx.tap.asObservable()
            .do(onNext: { (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { Session.shared.isAuthenticated }
            .subscribe(onNext: { (_) in
                SwiftEventBus.post(
                    AddBookToReadingEvent.EVENT_NAME,
                    sender: nil
                )
        }).disposed(by: self.disposeBag)
    }
}
