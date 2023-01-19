//
//  PopupNavigationController.swift
//  gat
//
//  Created by jujien on 7/24/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit

class PopupNavigationController: BottomPopupNavigationController {
    var height: CGFloat?
    var topCornerRadius: CGFloat?
    var presentDuration: Double?
    var dismissDuration: Double?
    var shouldDismissInteractivelty: Bool?
    
    override var popupHeight: CGFloat { return height ?? CGFloat(360.0) }
    
    override var popupTopCornerRadius: CGFloat { return topCornerRadius ?? CGFloat(20) }
    
    override var popupPresentDuration: Double { return presentDuration ?? 0.3 }
    
    override var popupDismissDuration: Double { return dismissDuration ?? 0.3 }
    
    override var popupShouldDismissInteractivelty: Bool { return shouldDismissInteractivelty ?? true }
    
    override var popupDimmingViewAlpha: CGFloat { return BottomPopupConstants.kDimmingViewDefaultAlphaValue }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.isHidden = true 
    }
}
