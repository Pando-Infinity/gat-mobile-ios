//
//  GatUpCollectionReusableView.swift
//  gat
//
//  Created by jujien on 12/31/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GatUpCollectionReusableView: UICollectionReusableView {
    
    class var identifier: String { return "header" }
    
    @IBOutlet weak var titleLabel: UILabel!
    
    let section: BehaviorRelay<GatUpViewController.Section> = .init(value: .barcode)
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.section.map { $0.name }.bind(to: self.titleLabel.rx.text).disposed(by: self.disposeBag)
    }
    
//    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
//        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
//        if #available(iOS 12, *) {} else {
//            switch self.section.value {
//            case .barcode, .gatup: attributes.frame = .zero
//            case .bookstop: attributes.frame = .init(x: 0.0, y: 120.0, width: UIScreen.main.bounds.width, height: 25.0)
//            case .information: attributes.frame = .init(x: 0.0, y: 120.0 + 156.0, width: UIScreen.main.bounds.width, height: 25.0)
//            }
//        }
//        return attributes
//    }
        
}
