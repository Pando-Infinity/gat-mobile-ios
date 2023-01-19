//
//  BookstopInfoCollectionViewCell.swift
//  gat
//
//  Created by jujien on 7/25/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ExpandableLabel

class BookstopInfoCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "bookstopInfoCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var aboutLabel: ExpandableLabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var numberBookLabel: UILabel!
    @IBOutlet weak var numberMemberLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var imgArrow:UIImageView!
    @IBOutlet weak var lbDirection:UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    var collapse: Bool = true
    var widthCell: CGFloat = 0.0
    
    var showMember: (() -> Void)?
    var showBook: (() -> Void)?
    let bookstop: BehaviorRelay<Bookstop?> = .init(value: nil)

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
//        self.layer.cornerRadius = 10
//        self.layer.borderColor = #colorLiteral(red: 0.9725490196, green: 0.6274509804, blue: 0.1960784314, alpha: 1)
//        self.layer.borderWidth = 1.0  
//        self.layer.masksToBounds = true
        self.aboutLabel.shouldCollapse = true
        self.aboutLabel.shouldExpand = true
        self.aboutLabel.collapsedAttributedLink = NSAttributedString(string: Gat.Text.BookDetail.MORE_TITLE.localized(), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
        self.aboutLabel.expandedAttributedLink = NSAttributedString.init(string: Gat.Text.LESS_TITLE.localized(), attributes:  [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
        self.imageView.layer.borderColor = #colorLiteral(red: 0.9725490196, green: 0.6274509804, blue: 0.1960784314, alpha: 1)
        self.imageView.layer.borderWidth = 2.0
        self.bookstop.map { $0?.profile?.name }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.bookstop.compactMap { $0?.profile?.imageId }.map { URL.init(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }.withLatestFrom(Observable.just(self.imageView), resultSelector: { ($0, $1) })
            .subscribe(onNext: { (url, imageView) in
                imageView?.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
            })
            .disposed(by: self.disposeBag)
        
        self.bookstop.map { $0?.profile?.address }.bind(to: self.addressLabel.rx.text).disposed(by: self.disposeBag)
        self.bookstop.compactMap { $0?.profile?.about }.withLatestFrom(Observable.just(self), resultSelector: { ($0, $1)})
            .subscribe(onNext: { (about, cell) in
                guard !about.isEmpty else { return }
                cell.aboutLabel.collapsed = cell.collapse
                cell.aboutLabel.text = about
            })
            .disposed(by: self.disposeBag)
        
        let sumary = self.bookstop.compactMap { $0?.kind as? BookstopKindOrganization }.share()
        sumary.map { "\($0.totalEdition)" }.map { (total) -> NSAttributedString in
            let text = total + " " + Gat.Text.BookstopOrganization.BOOKS_TITLE.localized()
            let attributes = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 1)])
            attributes.addAttributes([.font: UIFont.systemFont(ofSize: 24.0, weight: .bold), .foregroundColor: #colorLiteral(red: 0, green: 0.1417105794, blue: 0.2883770168, alpha: 1)], range: (text as NSString).range(of: total))
            return attributes
        }.bind(to: self.numberBookLabel.rx.attributedText).disposed(by: self.disposeBag)
        sumary.map { "\($0.totalMemeber)" }.map { (total) -> NSAttributedString in
            let text = total + " " + Gat.Text.BookstopOrganization.MEMBERS_TITLE.localized()
            let attributes = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 1)])
            attributes.addAttributes([.font: UIFont.systemFont(ofSize: 24.0, weight: .bold), .foregroundColor: #colorLiteral(red: 0, green: 0.1417105794, blue: 0.2883770168, alpha: 1)], range: (text as NSString).range(of: total))
            return attributes
        }.bind(to: self.numberMemberLabel.rx.attributedText).disposed(by: self.disposeBag)
        self.lbDirection.text = "DIRECTION_TITLE".localized()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.cornerRadius(radius: self.imageView.frame.width / 2.0)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attribute = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.widthCell != .zero {
            let margin: CGFloat = 16.0
            let spacing: CGFloat = 8.0
            let headerHeight: CGFloat = self.headerView.frame.height
            let aboutHeight: CGFloat = self.aboutLabel.sizeThatFits(.init(width: self.widthCell - margin * 2.0, height: .infinity)).height
            let addressHeight: CGFloat = self.addressLabel.sizeThatFits(.init(width: self.widthCell - margin * 2.0 - 15.0, height: .infinity)).height
            let numberHeight: CGFloat = self.numberBookLabel.frame.height
            let height = headerHeight + aboutHeight + spacing + addressHeight + margin + numberHeight + margin
            attribute.frame.size = .init(width: self.widthCell, height: height)
        }
        
        return attribute
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.numberMemberLabel.isUserInteractionEnabled = true
        self.numberBookLabel.isUserInteractionEnabled = true
        self.numberBookLabel.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.showBook?()
        }).disposed(by: self.disposeBag)
        
        self.numberMemberLabel.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.showMember?()
        }).disposed(by: self.disposeBag)
        
        self.imgArrow.rx.tapGesture().when(.recognized)
        .subscribe(onNext: { (_) in
            let user = self.bookstop.value?.profile
            let stringAddress = self.bookstop.value?.profile?.address
            guard let address = stringAddress?.replacingOccurrences(of: " ", with: "+") else {return}
            let urlString = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                print("URL: comgooglemaps://?q=\(urlString!)&center=\(user!.location.latitude),\(user!.location.longitude)&views=traffic&zoom=14")
                UIApplication.shared.open(URL(string: "comgooglemaps://?q=\(urlString!)&center=\(user!.location.latitude),\(user!.location.longitude)&views=traffic&zoom=14")!, options: [:], completionHandler: nil)
            } else {
                print("Can't use comgooglemaps://")
            }
        }).disposed(by: self.disposeBag)

    }

}

extension BookstopInfoCollectionViewCell {
    class func size(bookstop: Bookstop, collapse: Bool, in bounds: CGSize) -> CGSize {
        let margin: CGFloat = 16.0
        let spacing: CGFloat = 8.0
        let headerHeight: CGFloat = 88.0
        var aboutHeight: CGFloat = 0.0
        if let about = bookstop.profile?.about, !about.isEmpty {
            let aboutLabel = UILabel()
            aboutLabel.font = .systemFont(ofSize: 14.0)
            aboutLabel.text = about
            if collapse {
                aboutLabel.numberOfLines = 3
            } else {
                aboutLabel.numberOfLines = 0
            }
//            aboutLabel.shouldCollapse = collapse
//            aboutLabel.shouldExpand = !collapse
//            aboutLabel.numberOfLines = 3
//            aboutLabel.collapsedAttributedLink = NSAttributedString(string: Gat.Text.BookDetail.MORE_TITLE.localized(), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
//            aboutLabel.expandedAttributedLink = NSAttributedString.init(string: Gat.Text.LESS_TITLE.localized(), attributes:  [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: COLOR_BACKGROUND_COMMON])
//            aboutLabel.text = about
//            aboutLabel.collapsed = collapse
//            aboutLabel.sizeToFit()
            
            
            aboutHeight = aboutLabel.sizeThatFits(.init(width: bounds.width - margin * 2.0, height: .infinity)).height
            print(aboutHeight)
        }
        let address = UILabel()
        address.text = bookstop.profile?.address
        address.font = .systemFont(ofSize: 14.0)
        address.numberOfLines = 0
        let addressHeight: CGFloat = address.sizeThatFits(.init(width: bounds.width - margin * 2.0 - 15.0, height: .infinity)).height
        let numberHeight: CGFloat = 29.0
        let height = headerHeight + aboutHeight + spacing + addressHeight + margin + numberHeight + margin
        print("width: \(bounds.width), height: \(height)")
        return .init(width: bounds.width, height: height)
    }
}
