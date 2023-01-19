//
//  BookDetailSegmentView.swift
//  gat
//
//  Created by Vũ Kiên on 15/12/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class BookDetailSegmentView: UIView {
    
    @IBOutlet weak var infoImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var buyImageView: UIImageView!
    @IBOutlet weak var buyLabel: UILabel!
    @IBOutlet weak var newView: UIView!
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var buyView: UIView!
    @IBOutlet weak var leadingIndicatorConstraint: NSLayoutConstraint!
    
    weak var controller: BookDetailViewController?
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layoutIfNeeded()
        self.newView.cornerRadius(radius: self.newView.frame.height / 2.0)
        self.infoLabel.text = Gat.Text.BookDetail.BOOK_INFO_TITLE.localized()
        self.buyLabel.text = Gat.Text.BookDetail.BUY_BOOK_TITLE.localized()
        self.event()
    }
    
    fileprivate func event() {
        self.infoView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.controller?.performSegue(withIdentifier: BookDetailContainerController.segueIdentifier, sender: nil)
                self?.infoImageView.image = #imageLiteral(resourceName: "infoBlue")
                self?.buyImageView.image = #imageLiteral(resourceName: "buyIconGray")
                self?.infoLabel.textColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1)
                self?.buyLabel.textColor = #colorLiteral(red: 0.568627451, green: 0.568627451, blue: 0.568627451, alpha: 1)
                self?.animator(index: 0)
            })
            .disposed(by: self.disposeBag)
        
        self.buyView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.controller?.performSegue(withIdentifier: PriceViewController.segueIdentifier, sender: nil)
                self?.infoImageView.image = #imageLiteral(resourceName: "infoGray")
                self?.buyImageView.image = #imageLiteral(resourceName: "buyIconBlue")
                self?.infoLabel.textColor = #colorLiteral(red: 0.568627451, green: 0.568627451, blue: 0.568627451, alpha: 1)
                self?.buyLabel.textColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1)
                self?.animator(index: 1)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func animator(index: Int) {
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.leadingIndicatorConstraint.constant = CGFloat(index) * (self?.frame.width ?? 0.0) / 2.0
            self?.layoutIfNeeded()
        }
    }

}
