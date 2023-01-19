//
//  SecretRecoverPhraseView.swift
//  gat
//
//  Created by jujien on 02/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxDataSources

class SecretRecoverPhraseView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var isShowSecretRecoveryPhrase = false
    fileprivate let phrases = BehaviorRelay<[SectionModel<String, String>]>(value: [
        .init(model: "", items: ["extend", "keen", "cluster", "angry", "piece", "agree", "urban", "token", "around", "cotton", "cram", "thunder"])
    ])
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = "Tap to reveal your\nSecret Recover Phrase"
        self.cornerRadius = 16
        self.collectionView.register(UINib(nibName: TextCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: TextCollectionViewCell.identifier)
        self.collectionView.delegate = self
        var index = 0
        let count = self.phrases.value[0].items.count
        let datasource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, String>> { source, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextCollectionViewCell.identifier, for: indexPath) as! TextCollectionViewCell
            var i = indexPath.row
            if indexPath.row % 2 == 0 {
                i = indexPath.row - index
                index += 1
            } else {
                i = (count / 2 - 1 + index)
            }

            let value = source.sectionModels[indexPath.section].items[i]
            cell.label.text = "\(i + 1). \(value)"
            return cell
        }
        self.phrases.bind(to: self.collectionView.rx.items(dataSource: datasource)).disposed(by: self.disposeBag)
        
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.actionButton.rx.tap.bind { _ in
            if !self.isShowSecretRecoveryPhrase {
                self.isShowSecretRecoveryPhrase = true
                self.actionButton.setTitle("Copy to clipboard", for: .normal)
                self.collectionView.isHidden = false
                self.imageView.isHidden = true
                self.titleLabel.isHidden = true
                self.descriptionLabel.isHidden = true

            } else {
                UIPasteboard.general.string = self.phrases.value[0].items.joined(separator: " ")
            }
        }
        .disposed(by: self.disposeBag)
    }

}

extension SecretRecoverPhraseView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: (collectionView.frame.width - 96) / 2.0, height: self.collectionView.frame.height / 6)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: .zero, left: 32, bottom: .zero, right: 32)
    }
}
