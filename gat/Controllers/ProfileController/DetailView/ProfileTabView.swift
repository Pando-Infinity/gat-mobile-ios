//
//  ProfileTabView.swift
//  gat
//
//  Created by Vũ Kiên on 08/10/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

class ProfileTabView: UIView {
    
    @IBOutlet weak var sharingView: UIView!
    @IBOutlet weak var reviewView: UIView!
    @IBOutlet weak var requestView: UIView!
    @IBOutlet weak var selectView: UIView!
    @IBOutlet weak var sharingLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var requestLabel: UILabel!
    @IBOutlet weak var selectLeadingConstraint: NSLayoutConstraint!
    
    weak var controller: ProfileViewController?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.getData()
        self.event()
    }
    
    // MARK: - Data
    func getData() {
        self.getTotalBook()
        self.getTotalReviews()
        self.getTotalRecord()
    }
    
    fileprivate func getTotalBook() {
        InstanceNetworkService.shared.totalBook().catchErrorJustReturn(0).subscribe(onNext: { [weak self] (total) in
            self?.configureSharingBook(number: total)
            self?.controller?.saveUser(instanceCount: total, articleCount: nil, requestCount: nil)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func getTotalReviews() {
        PostService.shared.getTotalSelfPost(pageNum: 1).catchErrorJustReturn(0)
            .subscribe(onNext: { [weak self] (total) in
                self?.configureReviewBook(number: total)
                self?.controller?.saveUser(instanceCount: nil, articleCount: total, requestCount: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getTotalRecord() {
        RequestNetworkService.shared.total().catchErrorJustReturn(0)
            .subscribe(onNext: { [weak self] (total) in
                self?.configureBorrowingRequest(number: total)
                self?.controller?.saveUser(instanceCount: nil, articleCount: nil, requestCount: total)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    func configureSharingBook(number: Int) {
        let text = Gat.Text.UserProfile.BookInstance.BOOK_INSTANCE_TITLE.localized() + " \(number)"
        let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 1)]))
        attributes.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.631372549, green: 0.631372549, blue: 0.631372549, alpha: 1)], range: NSRange.init(location: text.count - " \(number)".count, length: " \(number)".count))
        self.sharingLabel.attributedText = attributes
    }
    
    func configureReviewBook(number: Int) {
        let text = Gat.Text.UserProfile.Review.REVIEW_TITLE.localized() + " \(number)"
        let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 1)]))
        attributes.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.631372549, green: 0.631372549, blue: 0.631372549, alpha: 1)], range: NSRange.init(location: text.count - " \(number)".count, length: " \(number)".count))
        self.reviewLabel.attributedText = attributes
    }
    
    func configureBorrowingRequest(number: Int) {
        let text = Gat.Text.UserProfile.Request.REQUEST_TITLE.localized() + " \(number)"
        let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 1)]))
        attributes.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.631372549, green: 0.631372549, blue: 0.631372549, alpha: 1)], range: NSRange.init(location: text.count - " \(number)".count, length: " \(number)".count))
        self.requestLabel.attributedText = attributes
    }
    
    fileprivate func changeSelect(index: Int) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.selectLeadingConstraint.constant = CGFloat(index) * (self?.frame.width ?? 0) / 3.0
            self?.layoutIfNeeded()
        }
    }
    
    //MARK: - Event
    func event() {
        self.selectTabSharingBook()
        self.selectTabReviewBook()
        self.selectTabBorrowingRequest()
    }
    
    fileprivate func selectTabSharingBook() {
        self.sharingView.rx.tapGesture().when(.recognized).bind { [weak self] (gesture) in
            self?.changeSelect(index: 0)
            self?.controller?.performSegue(withIdentifier: "showSharingBook", sender: nil)
        }.disposed(by: self.disposeBag)
    }
    
    fileprivate func selectTabReviewBook() {
        self.reviewView.rx.tapGesture().when(.recognized).bind { [weak self] (_) in
            self?.changeSelect(index: 1)
            self?.controller?.performSegue(withIdentifier: "showPersonalPost", sender: nil)
            }.disposed(by: self.disposeBag)
    }
    
    fileprivate func selectTabBorrowingRequest() {
        self.requestView.rx.tapGesture().when(.recognized).bind { [weak self] (gesture) in
            self?.changeSelect(index: 2)
            self?.controller?.performSegue(withIdentifier: "showBorrowingRequest", sender: nil)
        }.disposed(by: self.disposeBag)
    }
    
}
