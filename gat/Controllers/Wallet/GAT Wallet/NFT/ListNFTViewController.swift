//
//  ListNFTViewController.swift
//  gat
//
//  Created by jujien on 07/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class ListNFTViewController: UIViewController {
    
    class var segueIdentifier: String { "showListNFT" }
    
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let nfts = BehaviorRelay<[NFT]>(value: NFT.data)
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupNavigation()
        self.backButton.setTitle("", for: .normal)
        self.setupCollectionView()
    }
    
    fileprivate func setupNavigation() {
        self.view.layoutIfNeeded()
        self.navigationView.applyGradient(colors: [#colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1), #colorLiteral(red: 0.5725490196, green: 0.5921568627, blue: 0.9098039216, alpha: 1)], start: .zero, end: .init(x: 1.0, y: .zero))
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.backgroundColor = .white
        self.collectionView.delegate = self
        self.nfts.bind(to: self.collectionView.rx.items(cellIdentifier: NFTCollectionViewCell.identifier, cellType: NFTCollectionViewCell.self)) { index , item, cell in
            cell.nft.accept(item)
        }
        .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.collectionViewEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.bind { _ in
            self.navigationController?.popViewController(animated: true)
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(NFT.self)
            .bind { nft in
                self.performSegue(withIdentifier: NFTDetailViewController.segueIdentifier, sender: nft)
            }
            .disposed(by: self.disposeBag)
    }
    

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == NFTDetailViewController.segueIdentifier {
            let vc = segue.destination as? NFTDetailViewController
            vc?.nft.accept(sender as? NFT)
        }
    }


}

extension ListNFTViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width, height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 8.0, left: .zero, bottom: 8.0, right: .zero)
    }
}
