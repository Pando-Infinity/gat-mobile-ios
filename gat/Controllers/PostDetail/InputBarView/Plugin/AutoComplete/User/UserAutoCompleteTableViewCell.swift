//
//  UserAutoCompleteTableViewCell.swift
//  gat
//
//  Created by jujien on 5/15/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UserAutoCompleteTableViewCell: UITableViewCell {
    
    class var identifier: String { "userAutoCompleteCell" }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    let user: BehaviorRelay<UserPublic?> = .init(value: nil)
    fileprivate let disposeBag = DisposeBag()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.userImageView.circleCorner()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.userImageView.contentMode = .scaleAspectFill
        self.user.compactMap { $0?.profile.imageId }.map { URL.init(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }.bind(to: self.userImageView.rx.url(placeholderImage: DEFAULT_USER_ICON))
            .disposed(by: self.disposeBag)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
