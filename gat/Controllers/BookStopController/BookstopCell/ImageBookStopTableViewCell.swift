//
//  ImageBookStopTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 28/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ImageBookStopTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    weak var bookstopSpaceController: BookSpaceViewController?
    
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
    }
    
    //MARK: - UI
    func setupUI() {
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self
        self.registerCell()
        self.bookstopSpaceController?.bookstopController?
            .bookstop
            .map { $0.images }
            .bind(to: self.collectionView.rx.items(cellIdentifier: "imageCollectionCell", cellType: ImageCollectionViewCell.self))
            { (row, image, cell) in
                cell.imageView.sd_setImage(with: URL(string: image.url))
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func registerCell() {
        let nib = UINib.init(nibName: "ImageCollectionViewCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "imageCollectionCell")
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.collectionView
            .rx
            .modelDeselected(BookstopImage.self)
            .bind { [weak self] (bookstopImage) in
                self?.bookstopSpaceController?.bookstopController?.performSegue(withIdentifier: "showImageBookstop", sender: bookstopImage)
            }
            .disposed(by: self.disposeBag)
    }
}

extension ImageBookStopTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width - 6.5*4) / 3.0, height: (collectionView.frame.width - 6.5*4) / 3.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 6.5, left: 6.5, bottom: 6.5, right: 6.5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 6.5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6.5
    }
}
