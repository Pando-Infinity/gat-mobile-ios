//
//  CompletePublishPostViewController.swift
//  gat
//
//  Created by jujien on 9/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CompletePublishPostViewController: UIViewController {
    
    class var segueIdentifier: String { "showCompletePublishPost" }
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var completeLabel: UILabel!
    @IBOutlet weak var descriptionLLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var showButton: UIButton!
    
    let post = BehaviorRelay<Post?>(value: nil)
    
    weak var provider: StepCreateArticleProvider?
    
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.completeLabel.text = "SHOW_OFF_ACHIVEMENT_TITLE".localized()
        self.descriptionLLabel.text = "SHARE_POST_SOCIAL_TITLE".localized()
        self.shareButton.setTitle("SHARE_TITLE".localized(), for: .normal)
        self.showButton.setTitle("SHOW_ARTICLE".localized(), for: .normal)
        self.shareButton.cornerRadius(radius: 9.0)
        
        self.post.compactMap { $0 }.bind { post in
            NotificationCenter.default.post(name: Self.updatePost, object: post)
        }
        .disposed(by: self.disposeBag)
    }

    // MARK: - Event
    fileprivate func event() {
        self.cancelEvent()
        self.showEvent()
        self.shareEvent()
    }
    
    fileprivate func cancelEvent() {
        self.cancelButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.provider?.backScreen()
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showEvent() {
        self.showButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                guard let post = vc.post.value else { return }
                vc.provider?.backScreen()
                let storyboard = UIStoryboard(name: "PostDetail", bundle: nil)
                let postDetail = storyboard.instantiateViewController(withIdentifier: PostDetailViewController.className) as! PostDetailViewController
                postDetail.presenter = SimplePostDetailPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: postDetail))
                vc.navigationController?.pushViewController(postDetail, animated: true)
                
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func shareEvent() {
        self.shareButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                guard let post = vc.post.value else { return }
                let shareVC = vc.storyboard?.instantiateViewController(withIdentifier: SharePostViewController.className) as! SharePostViewController
                shareVC.presenter = SimpleSharePostPresenter(post: post)
                vc.present(shareVC, animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
    }
}

extension CompletePublishPostViewController {
    static let updatePost = Notification.Name(rawValue: "update_post")
}
