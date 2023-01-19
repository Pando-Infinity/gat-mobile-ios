//
//  SmallPostTbvCell.swift
//  gat
//
//  Created by macOS on 10/30/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class SmallPostTbvCell: UITableViewCell {
    
    @IBOutlet weak var containerView:UIView!
    fileprivate var contentPostView: SmallArticleView!
    
    var tapCellToOpenPostDetail:((OpenPostDetail,Bool)->Void)?
    var tapBook:((Bool)->Void)?
    var tapCatergory:((Bool)->Void)?
    var tapUser:((Bool)->Void)?
    var showOption: ((Post,Bool) -> Void)? {
        didSet {
            self.contentPostView.showOption = self.showOption
        }
    }
    let post = BehaviorRelay<Post?>(value: nil)
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    
    fileprivate func setupUI() {
        self.cornerRadius(radius: 10.0)
        self.contentPostView = Bundle.main.loadNibNamed(SmallArticleView.className, owner: self, options: nil)?.first as? SmallArticleView
        self.containerView.addSubview(self.contentPostView)
        
        self.contentPostView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.leading.equalToSuperview()
        }
        self.post.subscribe(onNext: self.contentPostView.post.accept).disposed(by: self.disposeBag)
    }
    
    fileprivate func event(){
        self.tapImgUser()
        self.tapPost()
        self.tapBookTitle()
    }
    
    fileprivate func tapImgUser(){
        self.contentPostView.userImageView.rx.tapGesture()
        .when(.recognized)
        .subscribe(onNext: { (_) in
            self.tapUser?(true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func tapBookTitle(){
        self.contentPostView.infoBookLabel.rx.tapGesture()
        .when(.recognized)
        .subscribe(onNext: { (_) in
            guard let arrCater = self.post.value?.categories else {return}
            if arrCater.contains(where: {$0.categoryId == 0}){
                self.tapBook?(true)
            } else {
                self.tapCatergory?(true)
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func tapPost(){
        let stackView:[UIView] = [self.contentPostView.viewContent]
        for i in stackView {
            i.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { (_) in
                    self.tapCellToOpenPostDetail?(OpenPostDetail.OpenNormal,true)
                }).disposed(by: self.disposeBag)
        }
    }
}
