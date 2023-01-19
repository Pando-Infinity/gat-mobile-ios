//
//  HashtagAndCategoryPostCollectionViewCell.swift
//  gat
//
//  Created by jujien on 9/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class HashtagAndCategoryPostView: UIView {
    
//    class var identifier: String { "hashtagAndCategoryPostFooter" }
    
    fileprivate let label = UILabel()
    fileprivate let containerView = UIView()
    
//    var sizeCell: CGSize = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    fileprivate func setupUI() {
        self.backgroundColor = .white
        self.containerView.backgroundColor = .white
        self.addSubview(self.containerView)
        self.containerView.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(16.0)
            if #available(iOS 11.0, *) {
                maker.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
            } else {
                maker.bottom.equalToSuperview()
            }
        }
        
        self.label.text = "ADD_CATERGORY_HASHTAG_TITLE".localized()
        self.label.font = .systemFont(ofSize: 14.0, weight: .semibold)
        self.label.textColor = .fadedBlue
        self.containerView.addSubview(self.label)
        self.label.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(16.0)
        }
        self.containerView.dropShadow(offset: .init(width: 0.0, height: -4.0), radius: 4.0, opacity: 0.5, color: #colorLiteral(red: 0.7411764706, green: 0.7411764706, blue: 0.7411764706, alpha: 1))
    }
    
}

//extension HashtagAndCategoryPostCollectionReusableView {
//    class func size(in bounds: CGSize) -> CGSize {
//        return .init(width: bounds.width, height: 68.0)
//    }
//}
