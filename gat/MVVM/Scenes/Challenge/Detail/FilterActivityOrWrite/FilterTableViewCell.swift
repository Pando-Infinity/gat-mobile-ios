//
//  FilterTableViewCell.swift
//  gat
//
//  Created by macOS on 9/23/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit

class FilterTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionViewFilter:UICollectionView!
    private var nibContent:UINib!
    fileprivate var selectIndexPath: IndexPath?
    fileprivate var selectItem: ChallengeDetailVC.Item = .article
    var cellSelected:((Int) -> Void)?
    var itemSelectedHandler: ((ChallengeDetailVC.Item) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.initCollectionView()
    }
    
    fileprivate func initCollectionView(){
        self.nibContent = UINib.init(nibName: "FilterCollectionViewCell", bundle: nil)
        self.collectionViewFilter.register(nibContent, forCellWithReuseIdentifier: "FilterCollectionViewCell")
        
        //Set delegate
        self.collectionViewFilter.dataSource = self
        self.collectionViewFilter.delegate = self
        self.collectionViewFilter.isScrollEnabled = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
}

extension FilterTableViewCell:UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.itemSelectedHandler?(ChallengeDetailVC.Item.allCases[indexPath.row])
        self.selectItem = ChallengeDetailVC.Item.allCases[indexPath.row]
        self.collectionViewFilter.reloadData()
    }
}

extension FilterTableViewCell:UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ChallengeDetailVC.Item.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCollectionViewCell", for: indexPath) as! FilterCollectionViewCell
        cell.lbNameFilter.text = ChallengeDetailVC.Item.allCases[indexPath.row].title
        if self.selectItem == ChallengeDetailVC.Item.allCases[indexPath.row] {
            cell.lbNameFilter.backgroundColor = UIColor(red: 90.0/255.0, green: 164.0/255.0, blue: 204.0/255.0, alpha: 1.0)
            cell.lbNameFilter.borderColor = UIColor(red: 90.0/255.0, green: 164.0/255.0, blue: 204.0/255.0, alpha: 1.0)
            cell.lbNameFilter.textColor = .white
        } else {
            cell.lbNameFilter.backgroundColor = .white
            cell.lbNameFilter.borderColor = UIColor(red: 155.0/255.0, green: 155.0/255.0, blue: 155.0/255.0, alpha: 1.0)
            cell.lbNameFilter.textColor = UIColor(red: 155.0/255.0, green: 155.0/255.0, blue: 155.0/255.0, alpha: 1.0)
        }
        return cell
    }
    
}

extension FilterTableViewCell:UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == 0 {
            return CGSize(width: 70.0, height: 38.0)
        }
        return CGSize(width: 85.0, height: 38.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
}
