//
//  PasscodeViewController.swift
//  gat
//
//  Created by jujien on 12/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class PasscodeViewController: UIViewController {
    
    class var segueIdentifier: String { "showPasscode" }
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var passcodeCollectionView: UICollectionView!
    @IBOutlet weak var numberCollectionView: UICollectionView!
    @IBOutlet weak var failedLabel: UILabel!
    
    fileprivate let numbers = BehaviorRelay<[Any]>(value: [1, 2, 3, 4, 5, 6, 7, 8, 9, "", 0, #imageLiteral(resourceName: "del_num")])
    fileprivate let passcodes = BehaviorRelay<[Int]>(value: [-1, -1, -1, -1, -1, -1])
    fileprivate var passcode = ""
    fileprivate var confirmPasscode = ""
    
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.failedLabel.isHidden = true
        self.backButton.setTitle("", for: .normal)
        self.view.applyGradient(colors: [#colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1), #colorLiteral(red: 0.5725490196, green: 0.5921568627, blue: 0.9098039216, alpha: 1)], start: .zero, end: .init(x: 1.0, y: 0.0))
        self.imageView.image = #imageLiteral(resourceName: "aboutGAT").withRenderingMode(.alwaysTemplate)
        self.imageView.tintColor = .white
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.setupNum()
        self.setupPasscode()
    }
    
    fileprivate func setupNum() {
        self.numberCollectionView.backgroundColor = .clear
        if let flowLayout = self.numberCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = .init(width: 56.0, height: 56.0)
            flowLayout.minimumLineSpacing = 20
            flowLayout.minimumInteritemSpacing = 40
            flowLayout.sectionInset = .zero
        }
        self.numbers.bind(to: self.numberCollectionView.rx.items(cellIdentifier: "cell", cellType: UICollectionViewCell.self)) { index, item, cell in
            if let number = item as? Int {
                let label = UILabel()
                label.text = "\(number)"
                label.textColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
                label.font = .systemFont(ofSize: 24, weight: .semibold)
                label.textAlignment = .center
                cell.addSubview(label)
                label.snp.makeConstraints { make in
                    make.top.equalToSuperview()
                    make.leading.equalToSuperview()
                    make.trailing.equalToSuperview()
                    make.bottom.equalToSuperview()
                }
                cell.backgroundColor = .white
            } else if item is String {
                cell.backgroundColor = .clear
            } else if let image = item as? UIImage {
                let imageView = UIImageView(image: image)
                cell.addSubview(imageView)
                cell.backgroundColor = .clear
                imageView.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.centerY.equalToSuperview()
                    make.width.equalTo(29)
                    make.height.equalTo(21)
                }
            }
            cell.circleCorner()
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupPasscode() {
        self.passcodeCollectionView.backgroundColor = .clear
        if let flowLayout = self.passcodeCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = .init(width: 16.0, height: 16.0)
            flowLayout.minimumLineSpacing = .zero
            flowLayout.minimumInteritemSpacing = 20
            flowLayout.sectionInset = .zero
        }
        self.passcodes.bind(to: self.passcodeCollectionView.rx.items(cellIdentifier: "cell", cellType: UICollectionViewCell.self)) { index, item, cell in
            if item != -1 {
                cell.backgroundColor = .white
            } else {
                cell.backgroundColor = .clear
            }
            cell.circleCorner()
            cell.borderWidth = 1.0
            cell.borderColor = .white
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
            if self.passcode.isEmpty {
                guard let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: WalletViewController.self)}) else { return }
                self.navigationController?.popToViewController(vc, animated: true)
            } else {
                self.passcode = ""
                self.passcodes.accept([-1, -1, -1, -1, -1, -1])
                self.failedLabel.isHidden = true
                self.descriptionLabel.text = "Confirm your passcode"
            }
            
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func collectionViewEvent() {
        self.numberCollectionView.rx
            .modelSelected(Any.self)
            .compactMap { $0 as? Int }
            .bind { value in
                self.failedLabel.isHidden = true
                var items = self.passcodes.value
                if let index = items.firstIndex(of: -1) {
                    items[index] = value
                    self.passcodes.accept(items)
                }
                if !items.contains(where: { $0 == -1}) {
                    if self.passcode.isEmpty {
                        self.passcode = items.map {"\($0)"}.joined()
                        self.passcodes.accept([-1, -1, -1, -1, -1, -1])
                        self.descriptionLabel.text = "Confirm your passcode"
                    } else {
                        let confirm = items.map { "\($0)" }.joined()
                        if confirm == self.passcode {
                            UserDefaults.standard.set(self.passcode, forKey: "passcode")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "wallet_success"), object: nil)
                            self.performSegue(withIdentifier: SuccessWalletViewController.segueIdentifier, sender: nil)
                        } else {
                            self.passcodes.accept([-1, -1, -1, -1, -1, -1])
                            self.failedLabel.isHidden = false
                        }
                    }
                }
            }
            .disposed(by: self.disposeBag)
        
        self.numberCollectionView.rx
            .modelSelected(Any.self)
            .compactMap { $0 as? UIImage }
            .bind { _ in
                var items = self.passcodes.value
                if let index = items.firstIndex(of: -1), index != 0 {
                    items[index - 1] = -1
                    self.passcodes.accept(items)
                }
            }
            .disposed(by: self.disposeBag)
            
    }

}
