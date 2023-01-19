//
//  EmptyReadingCollectionViewCell.swift
//  gat
//
//  Created by jujien on 1/17/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class EmptyReadingCollectionViewCell: UICollectionViewCell {
    class var identifier: String { return "emptyCell" }
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    
    let sizeCell = BehaviorRelay<CGSize>(value: .zero)
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.sizeCell.filter { $0 != .zero }.map { $0.width - 32.0 }.bind { [weak self] (value) in
            self?.descriptionLabel.preferredMaxLayoutWidth = value
        }.disposed(by: self.disposeBag)
        self.searchButton.setTitle("BUTTON_FIND_BOOK_NOW".localized(), for: .normal)
        self.descriptionLabel.text = "READING_LIST_SLOGAN".localized()
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell.value != .zero {
            attributes.frame.size = self.sizeCell.value
        }
        return attributes
    }
    
    @IBAction func onFindBook(_ sender: Any) {
        print("Send event")
        SwiftEventBus.post(OpenSearchBookEvent.EVENT_NAME)
    }
}

extension EmptyReadingCollectionViewCell {
    class func size(in collectionView: UICollectionView) -> CGSize {
        let width = collectionView.frame.width - 32.0
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "READING_LIST_SLOGAN".localized()
        label.font = .systemFont(ofSize: 14.0)
        let size = label.sizeThatFits(.init(width: width, height: .infinity))
        return .init(width: collectionView.frame.width, height: size.height + 78.0)
    }
}
