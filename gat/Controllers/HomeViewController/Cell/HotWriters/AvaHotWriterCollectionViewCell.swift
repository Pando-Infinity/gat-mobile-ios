//
//  AvaHotWriterCollectionViewCell.swift
//  gat
//
//  Created by macOS on 10/21/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AvaHotWriterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imgAveHotWriter:UIImageView!
    @IBOutlet weak var pageControlView:UIView!
    
    var user:BehaviorRelay<Profile> = .init(value: .init())
    let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
    }
    
//MARK: -UI
    fileprivate func setupUI(){
        self.pageControlView.cornerRadius = 1.5
        self.imgAveHotWriter.circleCorner()
        self.pageControlView.backgroundColor = UIColor.init(red: 90.0/255.0, green: 164.0/255.0, blue: 204.0/255.0, alpha: 1.0)
        self.contentView.backgroundColor = .clear
        self.user.compactMap { $0.imageId }.map { URL(string: AppConfig.sharedConfig.setUrlImage(id: $0)) }
            .bind(to: self.imgAveHotWriter.rx.url(placeholderImage: DEFAULT_USER_ICON))
            .disposed(by: self.disposeBag)
        self.imgAveHotWriter.contentMode = .scaleAspectFill
    }

}
