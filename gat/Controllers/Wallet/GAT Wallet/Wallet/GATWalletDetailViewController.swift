//
//  GATWalletDetailViewController.swift
//  gat
//
//  Created by jujien on 06/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxDataSources

class GATWalletDetailViewController: UIViewController {
    class var segueIdentifier: String { "showGATWalletDetail" }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var balanceLabel: UILabel!
    
    fileprivate let items = BehaviorRelay<[SectionModel<String, Item>]>(value: [
        .init(model: "Tokens", items: [
            .init(id: 0, name: "SOL", image: #imageLiteral(resourceName: "tabler_currency-solana"), color: #colorLiteral(red: 0.3803921569, green: 0.3529411765, blue: 0.7960784314, alpha: 0.15), value: 200),
            .init(id: 1, name: "GAT", image: #imageLiteral(resourceName: "iconoir_star"), color: #colorLiteral(red: 0.8941176471, green: 0.9490196078, blue: 0.9803921569, alpha: 1), value: 100)
            
        ]),
        .init(model: "NFT", items: [
            .init(id: 2, name: "GAT PFP", image: #imageLiteral(resourceName: "iconoir_mountain"), color: #colorLiteral(red: 1, green: 0.9607843137, blue: 0.8078431373, alpha: 1), value: 30),
            .init(id: 3, name: "Writer PFP", image: #imageLiteral(resourceName: "iconoir_book"), color: #colorLiteral(red: 0.8941176471, green: 0.9882352941, blue: 0.8823529412, alpha: 1), value: 20),
            .init(id: 4, name: "Archievments", image: #imageLiteral(resourceName: "carbon_trophy"), color: #colorLiteral(red: 0.9921568627, green: 0.9176470588, blue: 0.8784313725, alpha: 1), value: 10),
        ])
    ])
    
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        let total = WalletService.shared.totalPrice(network: .gat) + WalletService.shared.totalPrice(network: .sol)
        formatter.numberStyle = .currency
        self.balanceLabel.text = formatter.string(from: .init(value: total))
        
        self.items.accept([
            .init(model: "Tokens", items: [
                .init(id: 0, name: "SOL", image: #imageLiteral(resourceName: "tabler_currency-solana"), color: #colorLiteral(red: 0.3803921569, green: 0.3529411765, blue: 0.7960784314, alpha: 0.15), value:  WalletService.shared.totalPrice(network: .sol)),
                .init(id: 1, name: "GAT", image: #imageLiteral(resourceName: "iconoir_star"), color: #colorLiteral(red: 0.8941176471, green: 0.9490196078, blue: 0.9803921569, alpha: 1), value: WalletService.shared.totalPrice(network: .gat))
                
            ]),
            .init(model: "NFT", items: [
                .init(id: 2, name: "GAT PFP", image: #imageLiteral(resourceName: "iconoir_mountain"), color: #colorLiteral(red: 1, green: 0.9607843137, blue: 0.8078431373, alpha: 1), value: 30),
                .init(id: 3, name: "Writer PFP", image: #imageLiteral(resourceName: "iconoir_book"), color: #colorLiteral(red: 0.8941176471, green: 0.9882352941, blue: 0.8823529412, alpha: 1), value: 20),
                .init(id: 4, name: "Archievments", image: #imageLiteral(resourceName: "carbon_trophy"), color: #colorLiteral(red: 0.9921568627, green: 0.9176470588, blue: 0.8784313725, alpha: 1), value: 10),
            ])
        ])
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.backgroundColor = .white
        self.collectionView.delegate = self
        self.collectionView.register(.init(nibName: TitleHeaderCollectionReusableView.className, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TitleHeaderCollectionReusableView.identifier)
        
        let datasource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, Item>> { datasource, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GATWalletItemCollectionViewCell.identifier, for: indexPath) as! GATWalletItemCollectionViewCell
            cell.item.accept(item)
            return cell
        } configureSupplementaryView: { datasource, collectionView, kind, indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TitleHeaderCollectionReusableView.identifier, for: indexPath) as! TitleHeaderCollectionReusableView
            header.titleLabel.text = datasource[indexPath.section].identity
            header.subviews.filter { $0.tag == 1 }.forEach { $0.removeFromSuperview() }
            if indexPath.section == 1 {
                let view = UIView()
                view.backgroundColor = #colorLiteral(red: 0.9215686275, green: 0.9294117647, blue: 0.937254902, alpha: 1)
                view.tag = 1
                header.addSubview(view)
                view.snp.makeConstraints { make in
                    make.top.equalToSuperview()
                    make.leading.equalToSuperview().inset(16)
                    make.trailing.equalToSuperview().inset(16)
                    make.height.equalTo(1)
                }
            }
            
            return header
        }
        
        self.items.bind(to: self.collectionView.rx.items(dataSource: datasource)).disposed(by: self.disposeBag)
        
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.collectionViewEvent()
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(Item.self)
            .bind { item in
                if item.id == 0 || item.id == 1 {
                    self.performSegue(withIdentifier: WalletNetworkViewController.segueIdentifier, sender: item)
                } else if item.id == 2 || item.id == 3 || item.id == 4 {
                    self.performSegue(withIdentifier: ListNFTViewController.segueIdentifier, sender: nil)
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WalletNetworkViewController.segueIdentifier {
            let vc = segue.destination as? WalletNetworkViewController
            let id = (sender as! Item).id
            if id == 0 {
                vc?.network.accept(.sol)
            } else if id == 1 {
                vc?.network.accept(.gat)
            }
        }
    }
}

extension GATWalletDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: collectionView.frame.width, height: 32.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: .zero, left: .zero, bottom: 16.0, right: .zero)
    }
    
}

extension GATWalletDetailViewController {
    struct Item {
        var id: Int
        var name: String
        var image: UIImage
        var color: UIColor
        var value: Double
    }
    
}
