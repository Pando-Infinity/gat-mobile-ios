//
//  FilterCollectionViewCell.swift
//  gat
//
//  Created by macOS on 9/23/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FilterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var lbNameFilter:UILabel!
    var disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupFilterLabel()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.lbNameFilter.layer.cornerRadius = self.lbNameFilter.frame.size.height/2
        self.lbNameFilter.layer.masksToBounds = true
    }
    
    func setupFilterLabel(){
        self.lbNameFilter.borderWidth = 1.0
    }
}


@IBDesignable
class EdgeInsetLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                left: -textInsets.left,
                bottom: -textInsets.bottom,
                right: -textInsets.right)
        return textRect.inset(by: invertedInsets)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}

extension EdgeInsetLabel {
    @IBInspectable
    var leftTextInset: CGFloat {
        set { textInsets.left = newValue }
        get { return textInsets.left }
    }

    @IBInspectable
    var rightTextInset: CGFloat {
        set { textInsets.right = newValue }
        get { return textInsets.right }
    }

    @IBInspectable
    var topTextInset: CGFloat {
        set { textInsets.top = newValue }
        get { return textInsets.top }
    }

    @IBInspectable
    var bottomTextInset: CGFloat {
        set { textInsets.bottom = newValue }
        get { return textInsets.bottom }
    }
}
