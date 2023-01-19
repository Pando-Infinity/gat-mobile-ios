//
//  VistorUserTabView.swift
//  gat
//
//  Created by Vũ Kiên on 02/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class VistorUserTabView: UIView {
    
    @IBOutlet weak var sharingBookView: UIView!
    @IBOutlet weak var numberSharingBookLabel: UILabel!
    @IBOutlet weak var reviewBookView: UIView!
    @IBOutlet weak var numberReviewLabel: UILabel!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var selectLeadingConstraint: NSLayoutConstraint!
    
    weak var controller: UserVistorViewController?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configureBookSharing(total: 0)
        self.configureReviewBook(total: 0)
        self.event()
    }
    
    func configureBookSharing(total: Int) {
        let text = Gat.Text.VistorUserProfile.BookSharing.BOOK_SHARING_TITLE.localized() + " \(total)"
        let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 1)]))
        attributes.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.631372549, green: 0.631372549, blue: 0.631372549, alpha: 1)], range: NSRange.init(location: text.count - " \(total)".count, length: " \(total)".count))
        self.numberSharingBookLabel.attributedText = attributes
    }
    
    func configureReviewBook(total: Int) {
        let text = Gat.Text.VistorUserProfile.Review.REVIEW_TITLE.localized() + " \(total)"
        let attributes = NSMutableAttributedString(attributedString: NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 1)]))
        attributes.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.631372549, green: 0.631372549, blue: 0.631372549, alpha: 1)], range: NSRange.init(location: text.count - " \(total)".count, length: " \(total)".count))
        self.numberReviewLabel.attributedText = attributes
    }
    
    fileprivate func selected(index: Int) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.selectLeadingConstraint.constant = CGFloat(index) * (self?.frame.width ?? 0) / 2.0
            self?.layoutIfNeeded()
        }
    }
    
    fileprivate func event() {
        self.showBookSharing()
        self.showReviewBook()
    }
    
    fileprivate func showBookSharing() {
        self.sharingBookView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.selected(index: 0)
                self?.controller?.performSegue(withIdentifier: "showSharingBooksUserVistor", sender: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showReviewBook() {
        self.reviewBookView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.selected(index: 1)
                self?.controller?.performSegue(withIdentifier: "showVisitorPost", sender: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
}
