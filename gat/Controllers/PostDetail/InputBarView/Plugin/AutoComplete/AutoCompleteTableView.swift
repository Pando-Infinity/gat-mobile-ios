
//
//  AutoCompleteTableView.swift
//  gat
//
//  Created by jujien on 5/18/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit

class AutoCompleteTableView: UITableView {
    
    override var frame: CGRect {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    /// The max visible rows visible in the autocomplete table before the user has to scroll throught them
//    open var maxVisibleRows = 3 { didSet { self.invalidateIntrinsicContentSize() } }
    
    open override var intrinsicContentSize: CGSize {
//        CGFloat.infinity
//        let rows = self.numberOfRows(inSection: 0) < self.maxVisibleRows ? numberOfRows(inSection: 0) : maxVisibleRows
        return CGSize(width: super.intrinsicContentSize.width, height: self.frame.height)
    }
}
