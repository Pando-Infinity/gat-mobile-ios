//
//  BookstopTabItemView.swift
//  gat
//
//  Created by Vũ Kiên on 26/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

class BookstopTabItemView: UIView {

    @IBOutlet weak var bookView: UIView!
    @IBOutlet weak var bookSpaceView: UIView!
    @IBOutlet weak var numberBookLabel: UILabel!
    @IBOutlet weak var spaceBookLabel: UILabel!
    @IBOutlet weak var selectedLeadingConstraint: NSLayoutConstraint!
    
    weak var bookstopController: BookStopViewController?
    
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.event()
        self.spaceBookLabel.text = Gat.Text.Bookstop.BOOK_SPACE_TITLE.localized()
        self.configureBook(number: 0)
    }
    
    func configureBook(number: Int) {
        let text = Gat.Text.Bookstop.BOOK_TITLE.localized() + " \(number)"
        let attributes = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3058823529, alpha: 1)])
        attributes.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.631372549, green: 0.631372549, blue: 0.631372549, alpha: 1)], range: NSRange(location: text.count - " \(number)".count, length: " \(number)".count))
        self.numberBookLabel.attributedText = attributes
    }
    
    fileprivate func changeSelect(index: Int) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.selectedLeadingConstraint.constant = CGFloat(index) * (self?.frame.width ?? 0) / 2.0
            self?.layoutIfNeeded()
        }
    }
    
    fileprivate func event() {
        self.bookView
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (gesture) in
                self?.changeSelect(index: 0)
                self?.bookstopController?.performSegue(withIdentifier: "showBookCase", sender: nil)
            }
            .disposed(by: self.disposeBag)
        
        self.bookSpaceView
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (gesture) in
                self?.changeSelect(index: 1)
                self?.bookstopController?.performSegue(withIdentifier: "showBookSpace", sender: nil)
            }
            .disposed(by: self.disposeBag)
    }
}
