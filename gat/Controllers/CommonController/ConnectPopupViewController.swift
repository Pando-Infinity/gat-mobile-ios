//
//  ConnectPopupViewController.swift
//  gat
//
//  Created by Vũ Kiên on 26/03/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ConnectPopupViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!
    
    let disposeBag = DisposeBag()
    var message = Variable<String>("")
    var action: (() -> Void)!
    var isShow = false
    
    static var popup: ConnectPopupViewController?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.event()
        self.message.asObservable().bind(
            to: self.titleLabel.rx.text
        ).addDisposableTo(self.disposeBag)
        self.titleLabel.sizeToFit()
    }
    
    static func show(message: String, from viewcontroller: UIViewController, withFrame: CGRect, action: @escaping () -> Void) {
        if self.popup == nil {
            let storyboard = UIStoryboard(name: Gat.Storyboard.POPUP, bundle: nil)
            self.popup = storyboard.instantiateViewController(withIdentifier: Gat.View.CONNECT_POPUP_CONTROLLER) as? ConnectPopupViewController
        }
        
        self.popup?.action = action
        self.popup?.message.value = message
        viewcontroller.addChild(popup!)
        self.popup?.view.frame = withFrame
        viewcontroller.view.addSubview(popup!.view)
        self.popup?.didMove(toParent: viewcontroller)
        self.popup?.isShow = true
    }
    
    static func hiddenPopup() {
        self.popup?.isShow = false
        self.popup?.view.removeFromSuperview()
        self.popup?.removeFromParent()
    }
    
    fileprivate func event() {
        self.refreshButton.rx.controlEvent(.touchUpInside).bind {
            self.isShow = false
            self.view.removeFromSuperview()
            self.removeFromParent()
            self.action()
            }.disposed(by: self.disposeBag)
    }
    
    

}
