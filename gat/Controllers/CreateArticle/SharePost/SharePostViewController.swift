//
//  SharePostViewController.swift
//  gat
//
//  Created by jujien on 9/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import FacebookShare

class SharePostViewController: BottomPopupViewController {

    @IBOutlet weak var cancleButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titlePostLabel: UILabel!
    @IBOutlet weak var introPostLabel: UILabel!
    @IBOutlet weak var creatorLabel: UILabel!
    @IBOutlet weak var shareLinkButton: UIButton!
    @IBOutlet weak var shareFacebookButton: UIButton!
    
    override var popupHeight: CGFloat { return UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.height }
    
    override var popupTopCornerRadius: CGFloat { return 20.0 }
    
    override var popupPresentDuration: Double { return  0.3 }
    
    override var popupDismissDuration: Double { return 0.3 }
    
    override var popupShouldDismissInteractivelty: Bool { return true }
    
    override var popupDimmingViewAlpha: CGFloat { return BottomPopupConstants.kDimmingViewDefaultAlphaValue }
    
    var presenter: SharePostPresenter!
    
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.shareFacebookButton.cornerRadius = self.shareFacebookButton.frame.width / 2.0
        self.shareFacebookButton.layer.masksToBounds = true
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.presenter.post.map { $0.title }.bind(to: self.titlePostLabel.rx.text).disposed(by: self.disposeBag)
        self.presenter.post.map { $0.intro }.bind(to: self.introPostLabel.rx.text).disposed(by: self.disposeBag)
        self.presenter.post.map { (post) -> NSAttributedString in
            let text = "by \(post.creator.profile.name)"
            let attributed = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 12.0), .foregroundColor: UIColor.brownGrey])
            attributed.addAttributes([.foregroundColor: UIColor.navy], range: (text as NSString).range(of: post.creator.profile.name))
            return attributed
        }
        .bind(to: self.creatorLabel.rx.attributedText)
        .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.cancelEvent()
        self.linkEvent()
        self.shareFacebookEvent()
    }
    
    fileprivate func cancelEvent() {
        self.cancleButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.dismiss(animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func linkEvent() {
        self.shareLinkButton.rx.tap.withLatestFrom(self.presenter.post)
            .subscribe(onNext: { (post) in
                let url = AppConfig.sharedConfig.get("web_url") + "articles/\(post.id)"
                UIPasteboard.general.string = url
                let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self.present(controller, animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func shareFacebookEvent() {
        self.shareFacebookButton.rx.tap.withLatestFrom(self.presenter.post)
            .subscribe(onNext: { [weak self] (post) in
                guard let vc = self else { return }
                let content = ShareLinkContent()
                content.contentURL = URL(string: AppConfig.sharedConfig.get("web_url") + "articles/\(post.id)")!
                let dialog = ShareDialog.init(fromViewController: vc, content: content, delegate: nil)
                dialog.show()
            })
            .disposed(by: self.disposeBag)
    }
    
}
