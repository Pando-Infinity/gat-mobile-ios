//
//  ChallengeMembersVC.swift
//  gat
//
//  Created by Frank Nguyen on 1/12/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import SwipeMenuViewController

class ChallengeMembersVC: BaseViewController {
    
    override class var storyboardName: String {return "ChallengeMembersView"}
    
    @IBOutlet weak var swipeMenuView: SwipeMenuView!

    override func viewDidLoad() {

        super.viewDidLoad()
        
        swipeMenuView.delegate = self
        swipeMenuView.dataSource = self
        var options: SwipeMenuViewOptions = .init()
        options.tabView.style = .segmented
        options.tabView.itemView.textColor = Colors.blueLight
        options.tabView.itemView.selectedTextColor = Colors.blueDark
        
        options.tabView.additionView.backgroundColor = Colors.blueDark      // options customize
        swipeMenuView.reloadData(options: options)
        //swipeMenuView.reloadData(options: options, default: nil, isOrientationChange: true)
    }
}

extension ChallengeMembersVC: SwipeMenuViewDelegate {
    // MARK - SwipeMenuViewDelegate
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewWillSetupAt currentIndex: Int) {
        // Codes
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewDidSetupAt currentIndex: Int) {
        // Codes
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, willChangeIndexFrom fromIndex: Int, to toIndex: Int) {
        // Codes
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, didChangeIndexFrom fromIndex: Int, to toIndex: Int) {
        // Codes
    }
}

extension ChallengeMembersVC: SwipeMenuViewDataSource {
    // MARK - SwipeMenuViewDataSource

    func numberOfPages(in swipeMenuView: SwipeMenuView) -> Int {
        return 2
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, titleForPageAt index: Int) -> String {
        return "Tada"
    }

    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewControllerForPageAt index: Int) -> UIViewController {
        let viewController: UIViewController
        switch index {
            case 0:
                viewController = ChallengeMembersTabVC()
            case 1:
                viewController = ChallengeMembersTabVC()
            default:
                viewController = ChallengeMembersTabVC()
        }
        addChild(viewController)
        return viewController
    }
}

