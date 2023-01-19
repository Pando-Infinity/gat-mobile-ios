//
//  CreatePostRouter.swift
//  gat
//
//  Created by jujien on 8/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import Aztec

protocol CreatePostRouter {
    var viewController: UIViewController? { get }
    
    func backScreen()
    
    func showSetting(post: Post) -> Observable<Post>
    
    func showPreview(post: Post) -> Observable<Post>
}

extension CreatePostRouter {
    func showImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []
        picker.delegate = self.viewController as? CreatePostViewController
        picker.allowsEditing = false
        picker.navigationBar.isTranslucent = false
        picker.modalPresentationStyle = .currentContext
        self.viewController?.present(picker, animated: true, completion: nil)
    }
    
    func perform(segueIdentifier: String, sender: Any?) {
        self.viewController?.performSegue(withIdentifier: segueIdentifier, sender: sender)
    }
    
    func showAlert(error: Error) {
        HandleError.default.showAlert(with: error)
    }
    
    func showAlert(title: String, message: String) {
        guard let vc = self.viewController else { return }
        let ok = ActionButton.init(titleLabel: "OK", action: nil)
        AlertCustomViewController.showAlert(title: title, message: message, actions: [ok], in: vc)
    }
    
    func alertBack(selectItem: @escaping (CreateArticleAlertViewController.Item) -> Void) {
        let vc = self.viewController?.storyboard?.instantiateViewController(withIdentifier: CreateArticleAlertViewController.identifier) as! CreateArticleAlertViewController
        vc.select = selectItem
        self.viewController?.present(vc, animated: true, completion: nil)
    }
    
    func showOptionAlert(mediaAttachment: MediaAttachment, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actions.forEach(alert.addAction(_:))
        self.viewController?.present(alert, animated: true, completion: nil)
    }
}

struct SimpleCreatePostRouter: CreatePostRouter {
    
    weak var viewController: UIViewController?
    
    weak var provider: StepCreateArticleProvider?
    
    func backScreen() {
        self.provider?.backScreen()
    }
    
    func showSetting(post: Post) -> Observable<Post>  {
        let vc = self.viewController?.storyboard?.instantiateViewController(withIdentifier: SettingArticleViewController.className) as! SettingArticleViewController
        vc.presenter = SimpleSettingArticlePresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimpleSettingArticleRouter(viewController: vc, provider: self.provider))
        self.provider?.add(step: .init(controller: vc, direction: .forward))
        return vc.presenter.postUpdate

    }
    
    func showPreview(post: Post) -> Observable<Post> {
        let vc = self.viewController?.storyboard?.instantiateViewController(withIdentifier: PreviewPostViewController.className) as! PreviewPostViewController
        vc.presenter = SimplePreviewPostPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimplePreviewPostRouter(viewController: vc, provider: self.provider))
        self.provider?.add(step: .init(controller: vc, direction: .forward))
        return vc.presenter.post

    }
    
    
}
