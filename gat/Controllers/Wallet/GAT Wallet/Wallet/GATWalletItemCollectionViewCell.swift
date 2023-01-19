//
//  GATWalletItemCollectionViewCell.swift
//  gat
//
//  Created by jujien on 06/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class GATWalletItemCollectionViewCell: UICollectionViewCell {
    class var identifier: String { "gatWalletItemCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var forwardImageView: UIImageView!
    
    let item = BehaviorRelay<GATWalletDetailViewController.Item?>(value: nil)
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.item.map { $0?.name }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
        self.item.map { $0?.image }.bind(to: self.imageView.rx.image).disposed(by: self.disposeBag)
        self.item.compactMap { $0?.color }.bind(to: self.imageContainerView.rx.backgroundColor).disposed(by: self.disposeBag)
        self.item.compactMap { $0?.value }.map { "\(Int($0))" }.bind(to: self.valueLabel.rx.text).disposed(by: self.disposeBag)
        self.forwardImageView.tintColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
        self.forwardImageView.image = self.forwardImageView.image?.withRenderingMode(.alwaysTemplate)
    }
    
}
