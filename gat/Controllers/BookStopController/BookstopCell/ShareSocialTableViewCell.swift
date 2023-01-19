//
//  ShareSocialTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 28/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class ShareSocialTableViewCell: UITableViewCell {

    @IBOutlet weak var shareFacebookButton: UIButton!
    fileprivate let disposeBag = DisposeBag()
    
    weak var controller: BookSpaceViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
    }
    
    func setupUI() {
        self.layoutIfNeeded()
        self.shareFacebookButton.cornerRadius(radius: self.shareFacebookButton.frame.height / 2.0)
    }
    
    fileprivate func event() {
        self.shareFacebookButton
            .rx
            .controlEvent(.touchUpInside)
            .subscribe(onNext: { (_) in
                
            })
            .disposed(by: self.disposeBag)
    }

}
