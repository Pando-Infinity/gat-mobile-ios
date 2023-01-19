//
//  SettingArticleRouter.swift
//  gat
//
//  Created by jujien on 9/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol SettingArticleRouter {
    var viewController: UIViewController? { get }
    
    func openSelectArticle(selected: PostCategory?) -> Observable<PostCategory?>
    
    func backScreen()
}

extension SettingArticleRouter {
    func perform(segueIdentifier: String, sender: Any?) {
        self.viewController?.performSegue(withIdentifier: segueIdentifier, sender: sender)
    }
    
//    func openSelectArticle(selected: PostCategory?) {
//        self.perform(segueIdentifier: SelectCategoryPostViewController.segueIdentifier, sender: selected)
//    }
    
    func showImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []
        picker.delegate = self.viewController as? SettingArticleViewController
        picker.allowsEditing = false
        picker.navigationBar.isTranslucent = false
        picker.modalPresentationStyle = .currentContext
        self.viewController?.present(picker, animated: true, completion: nil)
    }
    
    func showAlert(error: Error) {
        HandleError.default.showAlert(with: error)
    }
}

struct SimpleSettingArticleRouter: SettingArticleRouter {
    weak var viewController: UIViewController?
    
    weak var provider: StepCreateArticleProvider?
    
    func openSelectArticle(selected: PostCategory?) -> Observable<PostCategory?> {
        let vc = self.viewController?.storyboard?.instantiateViewController(withIdentifier: SelectCategoryPostViewController.className) as! SelectCategoryPostViewController
        vc.presenter = SimpleSelectCategoryPostPresenter(selected: selected)
        vc.provider = self.provider
        self.provider?.add(step: .init(controller: vc, direction: .forward))
        return vc.presenter.selected.asObservable()
    }
    
    func backScreen() {
        self.provider?.popStep()
    }
}
