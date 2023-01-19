//
//  BookstopGatupView.swift
//  gat
//
//  Created by jujien on 1/1/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BookstopGatupView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var totalBookLabel: UILabel!
    @IBOutlet weak var totalMemberLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    let bookstop: BehaviorRelay<Bookstop> = .init(value: .init())
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.nameLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 112.0
        self.addressLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 112.0
        self.descriptionLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 64.0
        self.bookstop.map { $0.profile?.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.bookstop.map { $0.profile?.address }.bind(to: self.addressLabel.rx.text).disposed(by: self.disposeBag)
        self.bookstop.map { URL.init(string: AppConfig.sharedConfig.setUrlImage(id: $0.profile!.imageId )) }.subscribe(onNext: { [weak self] (url) in
            self?.imageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
        }).disposed(by: self.disposeBag)
        self.bookstop.map { $0.profile?.about }.bind(to: self.descriptionLabel.rx.text).disposed(by: self.disposeBag)
        let kind = self.bookstop.map { $0.kind as? BookstopKindOrganization }.filter { $0 != nil }.map { $0! }.share()
        kind.map { "\($0.totalEdition )" }.bind(to: self.totalBookLabel.rx.text).disposed(by: self.disposeBag)
        kind.map { "\($0.totalMemeber)" }.bind(to: self.totalMemberLabel.rx.text).disposed(by: self.disposeBag)
        self.layer.borderColor = #colorLiteral(red: 0.8784313725, green: 0.9058823529, blue: 0.9176470588, alpha: 1)
        self.layer.borderWidth = 1.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.circleCorner()
    }
    
    class func size(bookstop: Bookstop) -> CGSize {
        let width = UIScreen.main.bounds.width - 32.0
        let label = UILabel()
        label.text = bookstop.profile?.about
        label.font = .systemFont(ofSize: 14.0)
        label.numberOfLines = 0
        let size = label.sizeThatFits(.init(width: width - 32.0, height: .infinity))
        return .init(width: width, height: 94.0 + size.height + 8.0 + 16.0)
    }
    
}
