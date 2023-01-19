//
//  SuggestionBookTableViewCell.swift
//  gat
//
//  Created by jujien on 11/21/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SuggestionBookTableViewCell: UITableViewCell {
    
    class var identifier: String { return "suggestionBookCell" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!

    fileprivate let disposeBag = DisposeBag()
    
    let book: BehaviorRelay<BookInfo> = .init(value: BookInfo())
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.book.map { $0.title }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0.author }.bind(to: self.authorLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { $0.descriptionBook }.bind(to: self.descriptionLabel.rx.text).disposed(by: self.disposeBag)
        self.book.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0.imageId)) }.subscribe(onNext: { [weak self] (url) in
            self?.bookImageView.sd_setImage(with: url, placeholderImage: DEFAULT_BOOK_ICON)
        })
            .disposed(by: self.disposeBag)
    }
    
}
