//
//  InvitePersonTableViewCell.swift
//  gat
//
//  Created by macOS on 8/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class InvitePersonTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgUser:UIImageView!
    @IBOutlet weak var lbNameUser:UILabel!
    @IBOutlet weak var btnInviteUser:UIButton!
    var startHandle: ((Bool) -> Void)?
    var tapImgUser: ((Bool) -> Void)?
    
    var disposeBag = DisposeBag()
    
    var flagInvite:BehaviorRelay<(Int)> = .init(value: 1)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.imgUser.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { (_) in
                self.tapImgUser?(true)
            }).disposed(by: self.disposeBag)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupUI(){
        self.cornerRadius()
        self.setupBtnInvite()
    }
    
    func cornerRadius(){
        self.btnInviteUser.cornerRadius = 4.0
        self.imgUser.circleCorner()
        self.imgUser.layoutIfNeeded()
        self.imgUser.layer.masksToBounds = true
    }
    
    func setupBtnInvite(){
        //flag = 1 : not invite
        //flag = 2 : invited
        self.flagInvite.subscribe(onNext: { (flag) in
            if flag == 1 {
                self.btnInviteUser.backgroundColor = UIColor(red: 90.0/255.0, green: 164.0/255.0, blue: 204.0/255.0, alpha: 1.0)
                self.btnInviteUser.setImage(UIImage.init(named: "plus1"), for: .normal)
                self.btnInviteUser.setTitle(" "+"INVITE_TITLE".localized(), for: .normal)
            }
            if flag == 2 {
                self.btnInviteUser.backgroundColor = UIColor(red: 155.0/255.0, green: 155.0/255.0, blue: 155.0/255.0, alpha: 1.0)
                self.btnInviteUser.setImage(UIImage.init(named: "sent"), for: .normal)
                self.btnInviteUser.setTitle(" "+"INVITED_TITLE".localized(), for: .normal)
                self.btnInviteUser.isUserInteractionEnabled = false
            }
            }).disposed(by: disposeBag)
    }
    
    @IBAction func onInvite(_ sender: Any) {
        self.startHandle?(true)
    }
    
}
