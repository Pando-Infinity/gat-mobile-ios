//
//  StepCreateArticleViewController.swift
//  gat
//
//  Created by jujien on 9/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit

//typealias StepArticleController = UIViewController & StepCreateArticleProvider

struct StepCreateArticle {
    var controller: UIViewController
    var direction: UIPageViewController.NavigationDirection
    var animated: Bool = true
    var completion: ((Bool) -> Void)? = nil
}

protocol StepCreateArticleProvider: class {
    func add(step: StepCreateArticle)
    
    func popStep()
    
    func backScreen()
}

class StepCreateArticleViewController: UIViewController {
    
    fileprivate var pageController: UIPageViewController!
    
    fileprivate var steps: [StepCreateArticle] = []
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        self.setupUI()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.pageController = .init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageController.view.backgroundColor = .white
        self.pageController.view.frame = UIScreen.main.bounds
        self.addChild(self.pageController)
        self.view.addSubview(self.pageController.view)
        self.pageController.didMove(toParent: self)
    }

}

extension StepCreateArticleViewController: StepCreateArticleProvider {
    func add(step: StepCreateArticle) {
        self.steps.append(step)
        self.pageController.setViewControllers([step.controller], direction: step.direction, animated: step.animated, completion: step.completion)
    }
    
    func popStep() {
        _ = self.steps.popLast()
        guard var step = self.steps.last else { return }
        step.direction = .reverse
        self.pageController.setViewControllers([step.controller], direction: step.direction, animated: step.animated, completion: step.completion)
    }
    
    func backScreen() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
}

extension StepCreateArticleViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
