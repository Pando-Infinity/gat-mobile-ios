//
//  AlertChallengeCompleteVC.swift
//  gat
//
//  Created by Frank Nguyen on 1/30/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import FBSDKShareKit

protocol AlertChallengeCompleteDelegate {
    func onJoinOtherChallenge()
}

class AlertChallengeCompleteVC: BottomPopupViewController {

    var height: CGFloat?
    var topCornerRadius: CGFloat?
    var presentDuration: Double?
    var dismissDuration: Double?
    var shouldDismissInteractivelty: Bool?
    
    var image: UIImage?
    var challenge: Challenge?
    var challengeId: Int = 0
    var challengeName: String = ""
    var delegate: AlertChallengeCompleteDelegate?
    
    @IBOutlet weak var lbChallengeName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title challenge
        self.lbChallengeName.text = challengeName
    }
    
    @IBAction func onShare(_ sender: Any) {
        self.shareFacebook()
    }
    
    private func shareFacebook() {
        //guard let value = try? self.bookInfo.value() else { return }
        
        let content = ShareLinkContent()
        let web: String = AppConfig.sharedConfig.get("web_url")
//        if let image = self.image {
//            content.photos = [.init(image: image, userGenerated: true)]
//        } else if let challenge = challenge, let url = URL.init(string: AppConfig.sharedConfig.setUrlImage(id: challenge.imageCover, size: .o)) {
//            content.photos = [.init(imageURL: url, userGenerated: true)]
//        }
        content.hashtag = .init("#GATreadingchallenge")
        content.contentURL = URL(string: "\(web)challenges/\(self.challengeId)")!
        let dialog = ShareDialog.init(fromViewController: self, content: content, delegate: self)
        dialog.show()
    }
    
    @IBAction func onJoinOtherChallenge(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        delegate?.onJoinOtherChallenge()
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // Bottom popup attribute variables
    // You can override the desired variable to change appearance
    
    override var popupHeight: CGFloat { return height ?? CGFloat(445) }
    
    override var popupTopCornerRadius: CGFloat { return topCornerRadius ?? CGFloat(20) }
    
    override var popupPresentDuration: Double { return presentDuration ?? 0.3 }
    
    override var popupDismissDuration: Double { return dismissDuration ?? 0.3 }
    
    override var popupShouldDismissInteractivelty: Bool { return shouldDismissInteractivelty ?? true }
    
    override var popupDimmingViewAlpha: CGFloat { return BottomPopupConstants.kDimmingViewDefaultAlphaValue }
}

extension AlertChallengeCompleteVC: SharingDelegate {
    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        ToastView.makeToast("Chia sẻ thành công!")
    }
    
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {}
    
    func sharerDidCancel(_ sharer: Sharing) {}
}
