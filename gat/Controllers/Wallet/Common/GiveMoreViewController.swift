//
//  GiveMoreViewController.swift
//  gat
//
//  Created by jujien on 08/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class GiveMoreViewController: UIViewController {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var giveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    fileprivate let disposeBag = DisposeBag()
    
    let profile = BehaviorRelay<Profile?>(value: nil )
    let amount = BehaviorRelay<Double?>(value: nil)
    let amountOptions = BehaviorRelay<[Double]>(value: [])
    fileprivate let amountSelected = BehaviorRelay<Double>(value: 0)
    var giveHandler: ((Double) -> Void)?
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
        
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.cancelButton.setTitle("", for: .normal)
        self.setupDescription()
        self.setupCollectionView()
        self.amountOptions.skip(1).bind(onNext: { value in
            if value.isEmpty {
                fatalError()
            }
            self.amountSelected.accept(value[0])
        })
        .disposed(by: self.disposeBag)
        self.amountSelected.bind { _ in
            self.collectionView.reloadData()
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupDescription() {
        Observable.combineLatest(self.profile.compactMap { $0 }, self.amount.compactMap { $0 })
            .map { profile, amount in
            
                let text = "You just gave \(Int(amount)) GAT to \(profile.name) to appreciate their work. You still want to give more?"
                let attributeText = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)])
                attributeText.addAttributes([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)], range: (text as NSString).range(of: "\(Int(amount)) GAT"))
                attributeText.addAttributes([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)], range: (text as NSString).range(of: profile.name))
                return attributeText
            }
            .bind(to: descriptionLabel.rx.attributedText)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.backgroundColor = .white
        self.view.layoutIfNeeded()
        if let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = .init(width: self.collectionView.frame.width - 32.0, height: 32.0)
            flowLayout.minimumLineSpacing = .zero
            flowLayout.minimumInteritemSpacing = .zero
            flowLayout.sectionInset = .init(top: 6.0, left: .zero, bottom: 6.0, right: .zero)
        }
        self.amountOptions.bind(to: self.collectionView.rx.items(cellIdentifier: CheckboxCollectionViewCell.identifier, cellType: CheckboxCollectionViewCell.self)) { (index, item, cell) in
            cell.titleLabel.text = "\(Int(item)) GAT"
            cell.setupRadio(on: self.amountSelected.value == item)
        }
        .disposed(by: self.disposeBag)
    }
    
    func show() {
        if #available(iOS 13, *) {
            UIApplication.shared.windows.first?.rootViewController?.present(self, animated: true, completion: nil)
        } else {
            UIApplication.shared.keyWindow?.rootViewController!.present(self, animated: true, completion: nil)
        }

    }
    
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.collectionViewEvent()
        self.giveEvent()
    }
    
    fileprivate func backEvent() {
        self.cancelButton.rx.tap.bind { _ in
            self.dismiss(animated: true)
        }
        .disposed(by: self.disposeBag)
    }

    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(Double.self)
            .bind(onNext: self.amountSelected.accept(_:))
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func giveEvent() {
        self.giveButton.rx.tap.bind { _ in
            self.dismiss(animated: true) {
                self.giveHandler?(self.amountSelected.value)
            }
        }
        .disposed(by: self.disposeBag)
    }
}
