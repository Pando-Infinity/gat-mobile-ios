//
//  BookAutoCompleteTableViewCell.swift
//  gat
//
//  Created by jujien on 5/15/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BookAutoCompleteTableViewCell: UITableViewCell {
    
    class var identifier: String { "bookAutoCompleteCell" }
    
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    let book: BehaviorRelay<BookSharing?> = .init(value: nil)
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.book.map { $0?.info?.author }.bind(to: self.authorLabel.rx.text).disposed(by: self.disposeBag)
        self.book.compactMap { $0?.info?.imageId }.map { URL.init(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }.bind { [weak self] (url) in
            self?.bookImageView.sd_setImage(with: url, placeholderImage: DEFAULT_BOOK_ICON)
        }.disposed(by: self.disposeBag)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
