//
//  FooterReadingListCollectionReusableView.swift
//  gat
//
//  Created by jujien on 1/17/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class FooterReadingListCollectionReusableView: UICollectionReusableView {
    class var identifier: String { return "footer" }
    
    @IBOutlet weak var actionView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var actionHandle: (() -> Void)?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.actionView.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.actionHandle?()
        }).disposed(by: self.disposeBag)
    }
}
