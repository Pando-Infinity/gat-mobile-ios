//
//  PopupForMoreArticleVC.swift
//  gat
//
//  Created by macOS on 10/29/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class PopupForMoreArticleVC: BottomPopupViewController {
    
    @IBOutlet weak var btnSavePost:UIButton!
    @IBOutlet weak var btnSharePost:UIButton!
    @IBOutlet weak var btnDeletePost:UIButton!
    @IBOutlet weak var distanceDeleteOnBot: NSLayoutConstraint!
    @IBOutlet weak var distanceDeleteOnTop: NSLayoutConstraint!
    @IBOutlet weak var distanceShareOnTop: NSLayoutConstraint!
    @IBOutlet weak var distanceShareOnNormal: NSLayoutConstraint!
    
    
    var post:BehaviorRelay<Post?> = .init(value: nil)
    var isBookMark: BehaviorSubject<Bool> = .init(value: false)
    var isHideDelete: BehaviorSubject<Int> = .init(value: 0)
    //0:none 1:hideDelete 2:hideShareAndSave
    
    var isTapSave:((Bool)->Void)?
    var isTapShare:((Bool)->Void)?
    var isTapDelete:((Bool)->Void)?
    
    var disposeBag = DisposeBag()
    fileprivate var popHeight: CGFloat = 200.0

    override var popupHeight: CGFloat { return popHeight }
    
    override var popupTopCornerRadius: CGFloat { return 20.0 }
    
    override var popupDismissDuration: Double { return 0.2 }
    
    override var popupPresentDuration: Double { return 0.2 }
    
    override var popupShouldDismissInteractivelty: Bool { return true }
    
    override var popupDimmingViewAlpha: CGFloat { return 0.5 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.event()
        self.setupUI()
        self.checkUser()
        self.checkHideButton()
        self.checkLogin()
    }
    
    fileprivate func event(){
        self.eventSave()
        self.eventShare()
        self.eventDelete()
    }
    
    fileprivate func setupUI(){
        self.btnSharePost.setTitle("SHARE_POST_TITLE".localized(), for: .normal)
        self.btnDeletePost.setTitle("DELETE_POST_TITLE".localized(), for: .normal)
        self.post.compactMap{ $0?.saving }
            .map { $0 ? UIImage.init(named: "bookmarkedPost") : UIImage.init(named: "bookmarkPost") }
            .bind(to: self.btnSavePost.rx.image(for: .normal))
            .disposed(by: self.disposeBag)
        
        self.post.compactMap{ $0?.saving }
            .map { $0 ? "SAVED_POST_TITLE".localized() : "SAVE_POST_TITLE".localized() }
            .bind(to: self.btnSavePost.rx.title(for: .normal))
            .disposed(by: self.disposeBag)
        
        self.post.compactMap{ $0?.saving }
            .subscribe(self.isBookMark)
        .disposed(by: self.disposeBag)
        
        self.post.compactMap{ $0?.saving }
            .subscribe(onNext: { (status) in
            status ? self.btnSaveWhenBookMarked() : self.btnSaveWhenNotBookMark()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func btnSaveWhenBookMarked(){
        self.btnSavePost.setImage(UIImage.init(named: "bookmarkedPost"), for: .normal)
        self.btnSavePost.setTitle("SAVED_POST_TITLE".localized(), for: .normal)
    }
    
    fileprivate func btnSaveWhenNotBookMark(){
        self.btnSavePost.setImage(UIImage.init(named: "bookmarkPost"), for: .normal)
        self.btnSavePost.setTitle("SAVE_POST_TITLE".localized(), for: .normal)
    }
    
    fileprivate func checkUser(){
        let id = Repository<UserPrivate, UserPrivateObject>.shared.get()?.id
        self.post.subscribe(onNext: { (post) in
            let idUser = post?.creator.profile.id
            if idUser != id {
                self.btnDeletePost.isHidden = true
                self.popHeight = 150.0
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func checkLogin(){
        if !Session.shared.isAuthenticated {
            self.btnDeletePost.isHidden = true
            self.btnSavePost.isHidden = true
            self.distanceShareOnNormal.priority = .defaultLow
            self.distanceShareOnTop.priority = .defaultHigh
            self.popHeight = 95.0
        }
    }
    
    func checkHideButton(){
        self.isHideDelete.subscribe(onNext: { (flag) in
            if flag == 1 {
                self.btnDeletePost.isHidden = true
                self.popHeight = 150.0
            } else if flag == 2 {
                self.btnSavePost.isHidden = true
                self.btnSharePost.isHidden = true
                self.popHeight = 95.0
                self.distanceDeleteOnBot.priority = .defaultLow
                self.distanceDeleteOnTop.priority = .defaultHigh
            }
            
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func eventSave(){
        self.btnSavePost.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.isBookMark.onNext(!(try! self.isBookMark.value()))
                self.isTapSave?(true)
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func eventShare(){
        self.btnSharePost.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.isTapShare?(true)
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func eventDelete(){
        self.btnDeletePost.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.isTapDelete?(true)
            }).disposed(by: self.disposeBag)
    }

}
