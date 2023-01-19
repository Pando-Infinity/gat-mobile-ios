//
//  NFTDetailViewController.swift
//  gat
//
//  Created by jujien on 07/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class NFTDetailViewController: UIViewController {
    
    class var segueIdentifier: String { "showNFTDetail" }
    
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let nft = BehaviorRelay<NFT?>(value: nil)
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.backButton.setTitle("", for: .normal)
        self.setupNavigation()
        self.setupCollectionView()
    }
    
    fileprivate func setupNavigation() {
        self.view.layoutIfNeeded()
        self.navigationView.applyGradient(colors: [#colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1), #colorLiteral(red: 0.5725490196, green: 0.5921568627, blue: 0.9098039216, alpha: 1)], start: .zero, end: .init(x: 1.0, y: .zero))
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.backgroundColor = .white
        self.collectionView.delegate = self
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.collectionView.dataSource = self
        self.nft
            .compactMap({ nft in
                return nft
            })
            .bind { _ in
                self.collectionView.reloadData()
            }
        
            .disposed(by: self.disposeBag)

    }
    
    fileprivate func calculateSize() -> CGSize {
        guard let nft = self.nft.value else { return .zero }
        let heightImage = self.collectionView.frame.width - 32.0
        
        let idLabel = UILabel()
        idLabel.text = "#\(nft.id)"
        idLabel.font = .systemFont(ofSize: 12, weight: .medium)
        let sizeId = idLabel.sizeThatFits(.init(width: self.collectionView.frame.width - 48.0, height: .infinity))
        
        let nameLabel = UILabel()
        nameLabel.text = nft.name
        nameLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        nameLabel.numberOfLines = 0
        let sizeName = nameLabel.sizeThatFits(.init(width: self.collectionView.frame.width - 32.0, height: .infinity))
        
        let dateLabel = UILabel()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateLabel.text = "Mint: \(dateFormatter.string(from: nft.date))"
        dateLabel.font = .systemFont(ofSize: 14)
        let sizeDate = dateLabel.sizeThatFits(.init(width: self.collectionView.frame.width - 32.0, height: .infinity))
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = nft.description
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .systemFont(ofSize: 16)
        let sizeDescrition = descriptionLabel.sizeThatFits(.init(width: self.collectionView.frame.width - 32.0, height: .infinity))
        
        let height = 24 + heightImage + 16 + 4 + sizeId.height + 4 + 2 + sizeName.height + 4 + sizeDate.height + 16 + sizeDescrition.height + 16
        return CGSize(width: self.collectionView.frame.width, height: height)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.bind { _ in
            self.navigationController?.popViewController(animated: true)
        }
        .disposed(by: self.disposeBag)
    }
}

extension NFTDetailViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .white

        if let item = self.nft.value {

            let imageView = UIImageView()
            imageView.image = UIImage(named: item.image)
            cell.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.trailing.equalToSuperview().inset(16)
                make.top.equalToSuperview().inset(24)
                make.width.equalTo(imageView.snp.height)
            }
            imageView.circleCorner()


            let idView = UIView()
            idView.backgroundColor = #colorLiteral(red: 0.9568627451, green: 0.9490196078, blue: 0.9803921569, alpha: 1)
            idView.cornerRadius = 4.0
            cell.addSubview(idView)
            idView.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.top.equalTo(imageView.snp.bottom).offset(16)
            }

            let idLabel = UILabel()
            idLabel.text = "#\(item.id)"
            idLabel.font = .systemFont(ofSize: 12, weight: .medium)
            idLabel.textColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
            idView.addSubview(idLabel)
            idLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(4)
                make.bottom.equalToSuperview().inset(4)
                make.leading.equalToSuperview().inset(8)
                make.trailing.equalToSuperview().inset(8)
            }

            let nameLabel = UILabel()
            nameLabel.text = item.name
            nameLabel.font = .systemFont(ofSize: 24, weight: .semibold)
            nameLabel.textColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
            nameLabel.numberOfLines = 0
            cell.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16.0)
                make.top.equalTo(idView.snp.bottom).offset(2)
                make.trailing.equalToSuperview().inset(16)
            }

            let dateLabel = UILabel()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            dateLabel.text = "Mint: \(dateFormatter.string(from: item.date))"
            dateLabel.font = .systemFont(ofSize: 14)
            dateLabel.textColor = #colorLiteral(red: 0.5019607843, green: 0.5490196078, blue: 0.6117647059, alpha: 1)
            cell.addSubview(dateLabel)
            dateLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.top.equalTo(nameLabel.snp.bottom).offset(4.0)
            }

            let descriptionLabel = UILabel()
            descriptionLabel.text = item.description
            descriptionLabel.numberOfLines = 0
            descriptionLabel.font = .systemFont(ofSize: 16)
            descriptionLabel.textColor = #colorLiteral(red: 0.2, green: 0.2823529412, blue: 0.3803921569, alpha: 1)
            cell.addSubview(descriptionLabel)
            descriptionLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.top.equalTo(dateLabel.snp.bottom).offset(16)
                make.trailing.equalToSuperview().inset(16)
            }
        }
        return cell
    }
}


extension NFTDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.calculateSize()
    }
    
}
