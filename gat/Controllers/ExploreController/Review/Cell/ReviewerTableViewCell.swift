//
//  ReviewerTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 06/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

protocol ReviewerCellDelegate: class {
    func showView(identifier: String, sender: Any?)
}

class ReviewerTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: ReviewerCellDelegate?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupUI()
        self.getData()
    }
    
    fileprivate func getData() {
        Status
            .reachable
            .asObservable()
            .filter { $0 }
            .flatMap { _ in
                ReviewNetworkService
                    .shared
                    .topReviewers(previousDay: Int(AppConfig.sharedConfig.config(item: "previous_days")!)!)
                    .catchError { (error) -> Observable<[Reviewer]> in
                        HandleError.default.showAlert(with: error)
                        return Observable<[Reviewer]>.empty()
                    }
            }
            .filter { !$0.isEmpty }
            .bind(to: self.collectionView.rx.items(cellIdentifier: "nearbyBookstopCollectionCell", cellType: BoxCollectionViewCell.self)) { [weak self] (index, reviewer, cell) in
                cell.delegate = self
                cell.setupReview(reviewer: reviewer)
            }
            .disposed(by: self.disposeBag)
    }

    fileprivate func setupUI() {
        self.registerCell()
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self
    }
    
    fileprivate func registerCell() {
        let nib = UINib(nibName: "NearByBookstopCollectionViewCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "nearbyBookstopCollectionCell")
    }

}

extension ReviewerTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: collectionView.frame.width * 0.65, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
    }
}

extension ReviewerTableViewCell: BoxCollectionCellDelegate {
    func showView(identifire: String, sender: Any?) {
        self.delegate?.showView(identifier: identifire, sender: sender)
    }
}
