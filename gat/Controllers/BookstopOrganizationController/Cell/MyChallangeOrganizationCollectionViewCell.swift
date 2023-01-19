//
//  MyChallangeOrganizationCollectionViewCell.swift
//  gat
//
//  Created by jujien on 7/27/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MyChallangeOrganizationCollectionViewCell: UICollectionViewCell {

    class var identifier: String { "myChallangeOrganizationCell" }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    static let HEIGHT: CGFloat = 177.0
    
    let challenges = BehaviorRelay<[Challenge]>(value: [])
    var sizeCell: CGSize = .zero
    var showChallengeDetail: ((Challenge) -> Void)?
    fileprivate let disposeBag = DisposeBag()
    private var backgrounds = [#imageLiteral(resourceName: "myChallangeBackground1"), #imageLiteral(resourceName: "myChallangeBackground2"), #imageLiteral(resourceName: "myChallangeBackground3"), #imageLiteral(resourceName: "myChallangeBackground4")]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.delegate = self 
        self.collectionView.register(
            UINib(nibName: "MyChallengeCell", bundle: nil),
            forCellWithReuseIdentifier: "MyChallengeCell"
        )
        self.challenges.bind(to: self.collectionView.rx.items(cellIdentifier: MyChallengeCell.className, cellType: MyChallengeCell.self)) { (index, challenge, cell) in
            cell.setData(challenge: challenge)
            cell.backgroundImageView.image = self.backgrounds[index % self.backgrounds.count]
        }
        .disposed(by: self.disposeBag)
        
        self.collectionView.rx.modelSelected(Challenge.self).withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
            .subscribe(onNext: { (challenge, cell) in
                cell.showChallengeDetail?(challenge)
            })
            .disposed(by: self.disposeBag)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let layout = super.preferredLayoutAttributesFitting(layoutAttributes)
        if self.sizeCell != .zero {
            layout.frame.size = self.sizeCell
        }
        return layout
    }
}

extension MyChallangeOrganizationCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: 245, height: collectionView.frame.height - 16.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0.0, left: 16.0, bottom: 16.0, right: 16.0)
    }
}
