//
//  MyChallengeTableCell.swift
//  gat
//
//  Created by Frank Nguyen on 3/9/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class MyChallengeTableCell: UITableViewCell {
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var cvMyChallenges: UICollectionView!
    
    private var myChallenges: [Challenge] = []
    private var backgrounds = [#imageLiteral(resourceName: "myChallangeBackground1"), #imageLiteral(resourceName: "myChallangeBackground2"), #imageLiteral(resourceName: "myChallangeBackground3"), #imageLiteral(resourceName: "myChallangeBackground4")]
    
    override class func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func initView() {
        // Set delegate
        cvMyChallenges.delegate = self
        cvMyChallenges.dataSource = self
        // Register cells
        cvMyChallenges.register(
            UINib(nibName: "MyChallengeCell", bundle: nil),
            forCellWithReuseIdentifier: "MyChallengeCell"
        )
    }
    
    func setData(myChallenges: [Challenge]) {
        self.myChallenges = myChallenges
        self.cvMyChallenges.reloadData()
    }
    
    
}

// MARK - Set logic for CollectionView MyChallenges
extension MyChallengeTableCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (!myChallenges.isEmpty && myChallenges.count > indexPath.row) {
            //self.openChallengeDetail(idChallenge: myChallenges[indexPath.row].id)
            let idchallenge = myChallenges[indexPath.row].id
            SwiftEventBus.post(
                OpenChallengeDetailEvent.EVENT_NAME,
                sender: OpenChallengeDetailEvent(idchallenge)
            )
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myChallenges.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyChallengeCell", for: indexPath) as! MyChallengeCell
        cell.contentView.isUserInteractionEnabled = false
        if (!myChallenges.isEmpty && myChallenges.count > indexPath.row) {
            cell.setData(challenge: myChallenges[indexPath.row])
            cell.delegate = self
            cell.backgroundImageView.image = self.backgrounds[indexPath.row % self.backgrounds.count]
        }
        return cell
    }
}

extension MyChallengeTableCell: MyChallengeCellDelegate {
    func didTapUpdateChallenge() {
        SwiftEventBus.post(OpenReadingsEvent.EVENT_NAME)
    }
}

extension MyChallengeTableCell: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 245, height: 160)
    }
}

