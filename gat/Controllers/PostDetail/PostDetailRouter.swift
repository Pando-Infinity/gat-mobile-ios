//
//  PostDetailRouter.swift
//  gat
//
//  Created by jujien on 9/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit

protocol PostDetailRouter {
    var viewController: UIViewController? { get set }
}

extension PostDetailRouter {
    func backScreen() {
        self.viewController?.navigationController?.popViewController(animated: true)
    }
    
    func showAlert(error: Error) {
        HandleError.default.showAlert(with: error)
    }
    
    func openCommentSort(sortAction: @escaping (CommentPostFilter) -> Void) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        CommentPostFilter.allCases.forEach { (filter) in
            alert.addAction(.init(title: filter.title, style: .default, handler: { (_) in
                sortAction(filter)
            }))
        }
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        self.viewController?.present(alert, animated: true, completion: nil)
        
    }
    
    func showAlertDeleteComment(handler: @escaping () -> Void) {
        let alert = UIAlertController(title: "Notification", message: "ALERT_DELETE_COMMENT_TITLE".localized(), preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: { (_) in
            handler()
        }))
        alert.addAction(.init(title: "BUTTON_CANCEL".localized(), style: .cancel, handler: nil))
        self.viewController?.present(alert, animated: true, completion: nil)
    }
    
    func open(profile: Profile) {
        if profile.id == Session.shared.user?.id {
            let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
            vc.isShowButton.onNext(true)
            vc.hidesBottomBarWhenPushed = true
            self.viewController?.navigationController?.pushViewController(vc, animated: true)
        } else {
            let userPublic = UserPublic()
            userPublic.profile = profile
            self.viewController?.performSegue(withIdentifier: "showVistor", sender: userPublic)
        }
    }
    
    func openBookDetail(book: BookInfo) {
        self.viewController?.performSegue(withIdentifier: "showBookDetail", sender: book)
    }
    
    func openDetailCollectionArticle(type: TypeListArticle, hashtag: Hashtag) {
        let createArticle = UIStoryboard(name: "CreateArticle", bundle: nil)
        let vc = createArticle.instantiateViewController(withIdentifier: DetailCollectionArticleVC.className) as! DetailCollectionArticleVC
        vc.receiveTypePost.onNext(type)
        vc.titleScreen = "\(hashtag.name)"
        vc.arrHashtag.onNext([hashtag.id])
        self.viewController?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openDetailCollectionArticle(type: TypeListArticle, category: PostCategory) {
        let createArticle = UIStoryboard(name: "CreateArticle", bundle: nil)
        let vc = createArticle.instantiateViewController(withIdentifier: DetailCollectionArticleVC.className) as! DetailCollectionArticleVC
        vc.receiveTypePost.onNext(type)
        vc.titleScreen = category.title
        vc.arrCatergory.onNext([category.categoryId])
        self.viewController?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openListUserReaction(kind: SimpleListUserReactionPresenter.ListUserReactionKind, totalReaction: Int) {
        let storyboard = UIStoryboard(name: "ListUserReaction", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: ListUserReactionViewController.className) as! ListUserReactionViewController
        vc.presenter = SimpleListUserReactionPresenter(kind: kind, totalReaction: totalReaction)
        vc.openProfile = self.open(profile:)
        self.viewController?.present(vc, animated: true, completion: nil)
    }
}

struct SimplePostDetailRouter: PostDetailRouter {
    weak var viewController: UIViewController?
}
