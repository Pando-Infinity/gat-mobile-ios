//
//  NSRange+Extension.swift
//  gat
//
//  Created by jujien on 9/11/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit

extension NSRange {
    private init?(string: String, lowerBound: String.Index, upperBound: String.Index) {
        let utf16 = string.utf16

        guard let lowerBound = lowerBound.samePosition(in: utf16), let upperBound = upperBound.samePosition(in: utf16) else { return nil }
        let location = utf16.distance(from: utf16.startIndex, to: lowerBound)
        let length = utf16.distance(from: lowerBound, to: upperBound)

        self.init(location: location, length: length)
    }

    init?(range: Range<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }

    init?(range: ClosedRange<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
}
