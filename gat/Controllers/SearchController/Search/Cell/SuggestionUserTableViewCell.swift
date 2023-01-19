//
//  SuggestionUserTableViewCell.swift
//  gat
//
//  Created by jujien on 11/21/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SuggestionUserTableViewCell: UITableViewCell {
    
    class var identifier: String { return "suggestionUserCell" }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    
    let user: BehaviorRelay<Profile> = .init(value: .init())
    
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.user.map { $0.name }.bind(to: self.nameLabel.rx.text).disposed(by: self.disposeBag)
        self.user.map { $0.address }.bind(to: self.addressLabel.rx.text).disposed(by: self.disposeBag)
        self.user.map { $0.about }.bind(to: self.aboutLabel.rx.text).disposed(by: self.disposeBag)
        self.user.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0.imageId)) }.subscribe(onNext: { [weak self] (url) in
            self?.userImageView.sd_setImage(with: url, placeholderImage: DEFAULT_USER_ICON)
        }).disposed(by: self.disposeBag)
    }
}

extension SuggestionUserTableViewCell {
    class func size(user: Profile, in tableView: UITableView) -> CGFloat {
        let about = UILabel()
        about.text = user.about
        about.font = .systemFont(ofSize: 12.0)
        about.numberOfLines = 2
        let sizeAbout = about.sizeThatFits(.init(width: tableView.frame.width - 99.0, height: .infinity))
        let name = UILabel()
        name.text = user.name
        name.font = .systemFont(ofSize: 14.0)
        name.numberOfLines = 1
        let sizeName = name.sizeThatFits(.init(width: tableView.frame.width - 99.0, height: .infinity))
        let address = UILabel()
        address.text = user.address
        address.font = .systemFont(ofSize: 14.0)
        address.numberOfLines = 1
        let sizeAddress = name.sizeThatFits(.init(width: tableView.frame.width - 99.0, height: .infinity))
        let height = sizeAbout.height + sizeName.height + sizeAddress.height + 20.0 + 16.0
        return height > 95.0 ? height : 95.0
    }
}
