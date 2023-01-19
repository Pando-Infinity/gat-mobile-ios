//
//  InteractiveInputTextView.swift
//  gat
//
//  Created by jujien on 5/13/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import InputBarAccessoryView

extension InputTextView {
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let superBool = super.point(inside: point, with: event)

        var location = point
        print(location)
//        location.x -= self.textContainerInset.left
//        location.y -= self.textContainerInset.top
//
//        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
//        guard characterIndex < self.textStorage.length else { return superBool }
//        if let attributeValue = self.attributedText?.attribute(.autocompletedContext, at: characterIndex, effectiveRange: nil) as? [String: Any], let url = attributeValue["url"] as? URL {
//            let should = (self.delegate as? InputTextViewDelegate)?.textView(self, shouldInteractWith: url, context: attributeValue) ?? false
//            return should && superBool
//        }
        return superBool
    }
}

protocol InputTextViewDelegate: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, context: [String: Any]) -> Bool
}
