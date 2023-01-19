//
//  AztecEditorView.swift
//  gat
//
//  Created by jujien on 8/21/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import WordPressEditor
import Aztec
import RxCocoa
import RxSwift

//class AztecEditorView: EditorView {
//    
//    
//    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        if action == #selector(paste(_:)) ||
//            action == #selector(cut(_:)) ||
//            action == #selector(copy(_:)) ||
//            action == #selector(select(_:)) ||
//            action == #selector(selectAll(_:)) ||
//            action == #selector(delete(_:)) ||
//            action == #selector(makeTextWritingDirectionLeftToRight(_:)) ||
//            action == #selector(makeTextWritingDirectionRightToLeft(_:)) ||
//            action == #selector(toggleBoldface(_:)) ||
//            action == #selector(toggleItalics(_:)) ||
//            action == #selector(toggleUnderline(_:)) {
//            return false
//        }
//        return super.canPerformAction(action, withSender: sender)
//    }
//}

extension Reactive where Base: EditorView {
    var html: Binder<String> {
        .init(self.base) { (view, html) in
            view.setHTML(html)
        }
    }
}

extension Reactive where Base: TextView {
    var html: Binder<String> {
        .init(self.base) { (view, html) in
            view.setHTML(html)
        }
    }
}
