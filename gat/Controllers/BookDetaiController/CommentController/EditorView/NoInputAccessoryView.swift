//
//  NoInputAccessoryView.swift
//  gat
//
//  Created by Vũ Kiên on 27/03/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import WebKit

final class NoInputAccessoryView: NSObject {
    @objc var inputAccessoryView: AnyObject? { return nil }
}

extension WKWebView {
    func removeInputAccessory() {
        let targetView: UIView? = self.scrollView
            .subviews
            .filter { String(describing: type(of: $0)).hasPrefix("WKContent") }
            .first
        guard let target = targetView else {
            return
        }
        let noInputAccessoryViewClassName = "\(target.superclass!)NoInputAccessoryView"
        var newClass: AnyClass? = NSClassFromString(noInputAccessoryViewClassName)
        if newClass == nil {
            let targetClass: AnyClass = object_getClass(target)!
            newClass = objc_allocateClassPair(targetClass, noInputAccessoryViewClassName.cString(using: String.Encoding.ascii)!, 0)

        }
        let originalMethod = class_getInstanceMethod(NoInputAccessoryView.self, #selector(getter: NoInputAccessoryView.inputAccessoryView))
        class_addMethod(newClass!.self, #selector(getter: NoInputAccessoryView.inputAccessoryView), method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        object_setClass(target, newClass!)
    }
}

