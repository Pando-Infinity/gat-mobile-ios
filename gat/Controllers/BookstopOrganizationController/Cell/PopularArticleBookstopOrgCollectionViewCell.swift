//
//  PopularArticleBookstopOrgCollectionViewCell.swift
//  gat
//
//  Created by jujien on 8/18/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PopularArticleBookstopOrgCollectionViewCell: UICollectionViewCell {
    
    class var identifier: String { "popularArticleBookstopOrgCell" }
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let disposeBag = DisposeBag()
    
    var sizeCell: CGSize = .zero
    let posts: BehaviorRelay<[Post]> = .init(value: [])
    
    var position:Int = 0
    var tapCell:((OpenPostDetail,Bool)->Void)?
    var tapUser:((Bool)-> Void)?
    var tapBook:((Bool)-> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self 
        self.collectionView.register(UINib(nibName: MediumArticleBookstopCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: MediumArticleBookstopCollectionViewCell.identifier)
        self.posts.bind(to: self.collectionView.rx.items(cellIdentifier: MediumArticleBookstopCollectionViewCell.identifier, cellType: MediumArticleBookstopCollectionViewCell.self)) { (index, post, cell) in
            cell.post.accept(post)
            cell.tapUser = self.tapUser
            cell.tapBook = self.tapBook
            cell.tapCell = self.tapCell
            cell.rx.tapGesture().when(.recognized)
                .subscribe(onNext: { (_) in
                    self.position = index
                }).disposed(by: self.disposeBag)
        }.disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if #available(iOS 13.0, *) {
            if self.sizeCell != .zero {
                layout.frame.size = self.sizeCell
            }
        }
        return layout
    }
}

extension PopularArticleBookstopOrgCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width * 0.8, height: collectionView.frame.height - 32.0)
//        guard !self.posts.value.isEmpty && self.sizeCell != .zero else { return .zero }
//        return self.posts.value.map { MediumArticleBookstopCollectionViewCell.size(post: $0, in: .init(width: self.sizeCell.width * 0.8, height: .infinity)) }.max(by: { $0.height < $1.height })!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
    }
}
