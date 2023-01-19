//
//  STCollectionViewFlowLayout.swift
//  gat
//
//  Created by jujien on 7/27/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionView {
    static let elementKindSTSectionHeader = "elementKindSTSectionHeader"
}

class STCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }
    
//    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
//
//        let layoutAttributes = super.layoutAttributesForElements(in: rect)
//
//
//        guard let offset = collectionView?.contentOffset, let stLayoutAttributes = layoutAttributes else {
//            return layoutAttributes
//        }
//        if offset.y < 0 {
//
//            for attributes in stLayoutAttributes {
//
//                if let elmKind = attributes.representedElementKind, elmKind == UICollectionView.elementKindSTSectionHeader {
//
//                    let diffValue = abs(offset.y)
//                    var frame = attributes.frame
//                    frame.size.height = max(0, headerReferenceSize.height + diffValue)
//                    frame.origin.y = frame.minY - diffValue
//                    attributes.frame = frame
//                }
//            }
//        }
//        return layoutAttributes
//    }
}
