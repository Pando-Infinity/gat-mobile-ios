//
//  NFTCollectionViewCell.swift
//  gat
//
//  Created by jujien on 07/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class NFTCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "nftCell" }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var forwardImageView: UIImageView!
    
    let nft = BehaviorRelay<NFT?>(value: nil)
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.nft
            .compactMap { $0?.image }
            .map { UIImage(named: $0) }
            .bind(to: self.imageView.rx.image)
            .disposed(by: self.disposeBag)
        self.nft
            .compactMap { $0 }
            .map { "\($0.name) #\($0.id)" }
            .bind(to: self.nameLabel.rx.text)
            .disposed(by: self.disposeBag)
        self.forwardImageView.tintColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
        self.forwardImageView.image = self.forwardImageView.image?.withRenderingMode(.alwaysTemplate)
        
    }
    
}
