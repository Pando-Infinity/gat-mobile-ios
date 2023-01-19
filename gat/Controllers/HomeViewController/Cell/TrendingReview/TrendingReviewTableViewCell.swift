//
//  TrendingReviewTableViewCell.swift
//  gat
//
//  Created by macOS on 10/23/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TrendingReviewTableViewCell: UITableViewCell {
    
    @IBOutlet weak var clvTrendingReview:UICollectionView!
    var posts:[Post] = [] {
        didSet{
            self.clvTrendingReview.reloadData()
        }
    }
    
    var position:Int = 0
    var tapCell:((OpenPostDetail,Bool)->Void)?
    var tapUser:((Bool)-> Void)?
    var tapBook:((Bool)-> Void)?
    
    let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .white
        self.clvTrendingReview.backgroundColor = .white
        self.registerClv()
    }
    
    fileprivate func registerClv(){
        let nib = UINib(nibName: "MediumArticleBookstopCollectionViewCell", bundle: nil)
        self.clvTrendingReview.register(nib, forCellWithReuseIdentifier: MediumArticleBookstopCollectionViewCell.identifier)
        self.clvTrendingReview.dataSource = self
        self.clvTrendingReview.delegate = self
        self.clvTrendingReview.contentInset.left = 16.0
        self.clvTrendingReview.contentInset.top = 8.0
        if #available(iOS 13.0, *) {
            self.clvTrendingReview.automaticallyAdjustsScrollIndicatorInsets = false
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 11.0, *) {
            self.clvTrendingReview.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}

extension TrendingReviewTableViewCell:UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediumArticleBookstopCollectionViewCell.identifier, for: indexPath) as! MediumArticleBookstopCollectionViewCell
        cell.post.accept(self.posts[indexPath.row])
        cell.tapUser = self.tapUser
        cell.tapBook = self.tapBook
        cell.tapCell = self.tapCell
        cell.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { (_) in
                self.position = indexPath.row
            }).disposed(by: self.disposeBag)
        return cell
    }
    
    
}

extension TrendingReviewTableViewCell:UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 293.0, height: 380.0)
    }
}
