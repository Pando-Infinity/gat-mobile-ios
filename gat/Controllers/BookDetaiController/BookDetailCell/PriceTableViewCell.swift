//
//  PriceTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 15/11/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class PriceTableViewCell: UITableViewCell {
    
    class var identifier: String {
        return "priceCell"
    }
    
    @IBOutlet weak var typeImageView: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceBeforeDiscount: UILabel!
    @IBOutlet weak var discountLabel: UILabel!
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var seperateView: UIView!
    
    let price: BehaviorSubject<PriceBook> = .init(value: PriceBook())
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
    }
    
    fileprivate func setupUI() {
        self.price.subscribe(onNext: { [weak self] (price) in
            self?.typeLabel.text = price.from
            self?.priceLabel.text = price.price.currency()
            self?.discountLabel.text = String(format: "%.0f%%", price.discount)
            let attribute = NSMutableAttributedString(string: price.priceBeforeDiscount.currency() ?? "", attributes: [NSAttributedString.Key.strikethroughStyle: 2])
            self?.priceBeforeDiscount.attributedText = attribute
            self?.statusLabel.text = price.statusStock ? Gat.Text.BookDetail.STOCKING_TITLE.localized() : Gat.Text.BookDetail.OUT_OF_STOCK_TITLE.localized()
            self?.statusLabel.textColor = price.statusStock ? #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7333333333, alpha: 1) : #colorLiteral(red: 0.568627451, green: 0.568627451, blue: 0.568627451, alpha: 1)
            self?.statusImageView.image = price.statusStock ? #imageLiteral(resourceName: "iconBuyBlue") : #imageLiteral(resourceName: "iconBuyGray")
            self?.descriptionLabel.text = price.description
            switch price.from  {
            case "Fahasha":
                self?.typeImageView.image = #imageLiteral(resourceName: "fahasa1")
                self?.typeLabel.textColor = #colorLiteral(red: 0.7137254902, green: 0.03137254902, blue: 0.03137254902, alpha: 1)
                break
            case "Vinabook":
                self?.typeImageView.image = #imageLiteral(resourceName: "vinabook")
                self?.typeLabel.textColor = #colorLiteral(red: 0.2039215686, green: 0.5333333333, blue: 0.2352941176, alpha: 1)
                break
            case "Shopee":
                self?.typeImageView.image = #imageLiteral(resourceName: "shopee")
                self?.typeLabel.textColor = #colorLiteral(red: 0.7529411765, green: 0.1803921569, blue: 0.007843137255, alpha: 1)
                break
            case "Tiki":
                self?.typeImageView.image = #imageLiteral(resourceName: "tiki")
                self?.typeLabel.textColor = #colorLiteral(red: 0.3198930025, green: 0.6404747963, blue: 0.7817450762, alpha: 1)
                break
            default:
                break
            }
        }).disposed(by: self.disposeBag)
        self.price.subscribe(onNext: { [weak self] (price) in
            self?.discountView.isHidden = price.discount.isZero
            self?.typeLabel.isHidden = price.from.isEmpty
            self?.typeImageView.isHidden = price.from.isEmpty
            self?.statusLabel.isHidden = price.from.isEmpty
            self?.priceLabel.isHidden = price.from.isEmpty
            self?.priceBeforeDiscount.isHidden = price.from.isEmpty
            self?.statusImageView.isHidden = price.from.isEmpty
            self?.descriptionLabel.isHidden = price.from.isEmpty
            self?.seperateView.isHidden = price.from.isEmpty
        }).disposed(by: self.disposeBag)
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.discountView.cornerRadius(radius: self.discountView.frame.height / 2.0)
    }
}
