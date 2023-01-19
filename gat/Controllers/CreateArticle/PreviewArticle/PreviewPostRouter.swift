//
//  PreviewPostRouter.swift
//  gat
//
//  Created by jujien on 9/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol PreviewPostRouter {
    var viewController: UIViewController? { get set }
    
    func showCompete(post: Post)
    
    func backScreen()
}

extension PreviewPostRouter {
    func openAddHashtagCategory(post: Post) -> Observable<Post> {
        let vc = self.viewController?.storyboard?.instantiateViewController(withIdentifier: AddHashtahCategoryPostViewController.identifier) as! AddHashtahCategoryPostViewController
        vc.presenter = SimpleAddHashtagCategoryPostPresenter(post: post)
        self.viewController?.present(vc, animated: true, completion: nil)
        return vc.presenter.updatePost
    }
    
    func showAlert(error: Error) {
        HandleError.default.showAlert(with: error)
    }
    
    func perform(segueIdentifier: String, sender: Any?) {
        self.viewController?.performSegue(withIdentifier: segueIdentifier, sender: sender)
    }
}

struct SimplePreviewPostRouter: PreviewPostRouter {
    weak var viewController: UIViewController?
    
    weak var provider: StepCreateArticleProvider?
    
    func showCompete(post: Post) {
        let vc = self.viewController?.storyboard?.instantiateViewController(withIdentifier: CompletePublishPostViewController.className) as! CompletePublishPostViewController
        vc.post.accept(post)
        vc.provider = self.provider
        self.provider?.add(step: .init(controller: vc, direction: .forward))
    }
    
    func backScreen() {
        self.provider?.popStep()
    }
}
