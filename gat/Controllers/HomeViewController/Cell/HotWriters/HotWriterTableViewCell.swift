//
//  HotWriterTableViewCell.swift
//  gat
//
//  Created by macOS on 10/21/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class HotWriterTableViewCell: UITableViewCell {
    
    @IBOutlet weak var clvHotWriter: UICollectionView!
    @IBOutlet weak var viewName:UIView!
    @IBOutlet weak var lbNameWriter:UILabel!
    @IBOutlet weak var btnGoMore:UIButton!
    @IBOutlet weak var view1:UIView!
    @IBOutlet weak var view2:UIView!
    var viewPost1:SmallArticleView!
    var viewPost2:SmallArticleView!
    var post1 = BehaviorRelay<Post?>(value: nil)
    var post2 = BehaviorRelay<Post?>(value: nil)
    var tapCellToOpenPostDetail:((Int,Bool)->Void)?
    
    var userSelectedHandle:((Int)->Void)?
    var goMoreEvent:((Bool)->Void)?
    var nameUser:BehaviorRelay<String> = .init(value: " ")
    var selectedUser:Int = 0
    var writer:[HotWriter] = [] {
        didSet {
            self.clvHotWriter.reloadData()
        }
    }
    
    var disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.registerClv()
        self.clvHotWriter.delegate = self
        self.clvHotWriter.dataSource = self
        self.setupUI()
        self.nameUser.map { $0 }.bind(to: self.lbNameWriter.rx.text).disposed(by: self.disposeBag)
        self.btnGoMore.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { (_) in
                self.goMoreEvent?(true)
            }).disposed(by: self.disposeBag)
        self.viewPost1.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.tapCellToOpenPostDetail?(1,true)
            }).disposed(by: self.disposeBag)
        self.viewPost2.rx.tapGesture()
        .when(.recognized)
        .subscribe(onNext: { (_) in
            self.tapCellToOpenPostDetail?(2,true)
        }).disposed(by: self.disposeBag)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    fileprivate func registerClv(){
        let nib = UINib(nibName: AvaHotWriterCollectionViewCell.className, bundle: nil)
        self.clvHotWriter.register(nib, forCellWithReuseIdentifier: AvaHotWriterCollectionViewCell.className)
    }
    
//MARK: -UI
    fileprivate func setupUI(){
        self.contentView.backgroundColor = UIColor.init(red: 90.0/255.0, green: 164.0/255.0, blue: 204.0/255.0, alpha: 0.12)
        self.clvHotWriter.backgroundColor = .clear
        self.clvHotWriter.isUserInteractionEnabled = true
        self.clvHotWriter.contentInset.left = 16.0
        self.clvHotWriter.contentInset.top = 2.0
        self.viewName.backgroundColor = .white
        
        self.viewPost1 = Bundle.main.loadNibNamed(SmallArticleView.className, owner: self, options: nil)?.first as? SmallArticleView
        self.view1.addSubview(self.viewPost1)
        self.viewPost1.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(-40.0)
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.leading.equalToSuperview()
        }
        
        self.post1.subscribe(onNext: self.viewPost1.post.accept).disposed(by: self.disposeBag)
        
        self.viewPost2 = Bundle.main.loadNibNamed(SmallArticleView.className, owner: self, options: nil)?.first as? SmallArticleView
        self.view2.addSubview(self.viewPost2)
        self.viewPost2.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(-40.0)
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.leading.equalToSuperview()
        }
        
        self.post2.subscribe(onNext: self.viewPost2.post.accept).disposed(by: self.disposeBag)
        
        self.viewPost1.hideHeader(hide: true)
        self.viewPost2.hideHeader(hide: true)
        
    }
    
    override func layoutSubviews() {
        self.viewName.roundCorners(corners: [.topLeft, .topRight], radius: 9.0)
        self.view2.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 9.0)
    }
    
}

extension HotWriterTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.writer.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AvaHotWriterCollectionViewCell.className, for: indexPath) as! AvaHotWriterCollectionViewCell
        cell.user.accept(self.writer[indexPath.item].profile)
        if self.selectedUser == indexPath.row {
            cell.imgAveHotWriter.borderWidth = 2.0
            cell.imgAveHotWriter.borderColor = UIColor.init(red: 90.0/255.0, green: 164.0/255.0, blue: 204.0/255.0, alpha: 1.0)
            cell.pageControlView.isHidden = false
        } else {
            cell.imgAveHotWriter.borderWidth = 0.0
            cell.pageControlView.isHidden = true
        }
        return cell
    }
}

extension HotWriterTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width:Double = 48.0
        let height:Double = 76.0
        return CGSize.init(width: width, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
}

extension HotWriterTableViewCell:UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedUser = indexPath.row
        self.userSelectedHandle?(indexPath.row)
        self.clvHotWriter.reloadData()
    }
}
