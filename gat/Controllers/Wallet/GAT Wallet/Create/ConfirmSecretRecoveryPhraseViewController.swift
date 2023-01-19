//
//  ConfirmSecretRecoveryPhraseViewController.swift
//  gat
//
//  Created by jujien on 02/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxDataSources

class ConfirmSecretRecoveryPhraseViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var selectionCollectionView: UICollectionView!
    @IBOutlet weak var confirmCollectionView: UICollectionView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var forwardImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let listItemSelections = BehaviorRelay<[String]>(value: ["extend", "keen", "cluster", "angry", "piece", "agree", "urban", "token", "around", "cotton", "cram", "thunder"].shuffled())
    fileprivate let items = BehaviorRelay<[SectionModel<String, String>]>(value: [
        .init(model: "", items: ["", "", "", "", "", "", "", "", "", "", "", ""])
    ])

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.progressLabel.text = "Creating wallet....\nThis shouldn't take long."
        self.progressLabel.isHidden = true
        self.imageView.isHidden = true
        self.progressView.isHidden = true
        self.view.applyGradient(colors: [#colorLiteral(red: 0.4039215686, green: 0.7098039216, blue: 0.8745098039, alpha: 1), #colorLiteral(red: 0.5725490196, green: 0.5921568627, blue: 0.9098039216, alpha: 1)], start: .zero, end: .init(x: 1.0, y: 0.0))
        self.setupCollectionView()
        self.items.map { $0[0].items }
            .map { items in
                return items.reduce(true) { result, element in
                    return result && !element.isEmpty
                }
            }
            .do(onNext: { value in
                if value {
                    self.forwardImageView.image = #imageLiteral(resourceName: "forward")
                } else {
                    self.forwardImageView.image = #imageLiteral(resourceName: "forward").withRenderingMode(.alwaysTemplate)
                    self.forwardImageView.tintColor = #colorLiteral(red: 0.7019607843, green: 0.7294117647, blue: 0.768627451, alpha: 1)
                }
            })
            .bind(to: self.nextButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupCollectionView() {
        self.setupSelection()
        self.setupConfirm()
    }
    
    fileprivate func setupSelection() {
        self.selectionCollectionView.backgroundColor = .clear
        if let flowLayout = self.selectionCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            flowLayout.minimumLineSpacing = 12.0
            flowLayout.minimumInteritemSpacing = 6.0
        }
        self.listItemSelections.bind(to: self.selectionCollectionView.rx.items(cellIdentifier: "cell", cellType: UICollectionViewCell.self)) { index, item , cell in
            cell.subviews.forEach { $0.removeFromSuperview() }
            let contain = self.items.value[0].items.contains(where: { $0 == item })
            let label = UILabel()
            label.text = item
            label.font = .systemFont(ofSize: 14.0)
            label.textColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
            cell.addSubview(label)
            label.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(8.0)
                make.leading.equalToSuperview().offset(16.0)
                make.trailing.equalToSuperview().inset(16.0)
                make.bottom.equalToSuperview().inset(8.0)
            }
            cell.cornerRadius = 16.0
            cell.backgroundColor = contain ? #colorLiteral(red: 0.6666666667, green: 0.8549019608, blue: 0.9803921569, alpha: 1) : .white
            cell.borderColor = #colorLiteral(red: 0.9215686275, green: 0.9294117647, blue: 0.937254902, alpha: 1)
            cell.borderWidth = 1.5
        }
        .disposed(by: self.disposeBag)
            
    }
    
    fileprivate func setupConfirm() {
        self.confirmCollectionView.backgroundColor = .white
        self.confirmCollectionView.cornerRadius = 16.0
        self.confirmCollectionView.borderWidth = 1.5
        self.confirmCollectionView.borderColor = #colorLiteral(red: 0.9215686275, green: 0.9294117647, blue: 0.937254902, alpha: 1)
        self.confirmCollectionView.register(UINib(nibName: TextCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: TextCollectionViewCell.identifier)
        self.view.layoutIfNeeded()
        if let flowLayout = self.confirmCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumLineSpacing = .zero
            flowLayout.minimumInteritemSpacing = 32.0
            flowLayout.itemSize = .init(width: (self.confirmCollectionView.frame.width - 96.0) / 2.0, height: self.confirmCollectionView.frame.height / 6.0)
            flowLayout.sectionInset = UIEdgeInsets(top: .zero, left: 32, bottom: .zero, right: 32)
        }
        var index = 0
        self.items.bind { _ in
            index = 0
        }
        .disposed(by: self.disposeBag)
        let count = self.items.value[0].items.count
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
        self.items.bind(to: self.confirmCollectionView.rx.items(dataSource: datasource)).disposed(by: self.disposeBag)
    }
    
    fileprivate func showProgress() {
        self.progressView.isHidden = false
        self.imageView.isHidden = false
        self.progressLabel.isHidden = false
        self.confirmCollectionView.isHidden = true
        self.selectionCollectionView.isHidden = true
        self.backButton.isHidden = true
        self.forwardImageView.isHidden = true
        self.nextButton.isHidden = true
        self.titleLabel.isHidden = true
        self.descriptionLabel.isHidden = true
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.progressView.progress == 1.0 {
                timer.invalidate()
                if UserDefaults.standard.string(forKey: "passcode") != nil && UserDefaults.standard.string(forKey: "passcode") != "" {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "wallet_success"), object: nil)
                    self.performSegue(withIdentifier: SuccessWalletViewController.segueIdentifier, sender: nil)
                } else {
                    self.performSegue(withIdentifier: PasscodeViewController.segueIdentifier, sender: nil)
                }
            } else {
                self.progressView.progress += 0.1
            }
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.collectionViewEvent()
        self.nextEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.bind { _ in
            self.navigationController?.popViewController(animated: true)
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func nextEvent() {
        self.nextButton.rx.tap
            .map({ _ in
                let items = self.items.value[0].items
                return items.enumerated().map { (offset, value) in
                    return ["extend", "keen", "cluster", "angry", "piece", "agree", "urban", "token", "around", "cotton", "cram", "thunder"][offset] == value
                }
                .reduce(true) { partialResult, value in
                    return partialResult && value
                }
            })
            .bind { value in
//                if !value {
//                    AlertCustomViewController.showAlert(title: Gat.Text.CommonError.ERROR_ALERT_TITLE.localized(), message: "Secret Recovery Phrase is incorrect", actions: [.init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized(), action: nil)], in: self)
//                } else {
//                    self.showProgress()
//                }
                self.showProgress()
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func collectionViewEvent() {
        self.selectionCollectionView.rx.modelSelected(String.self)
            .bind { value in
                var items = self.items.value[0].items
                if let index = items.firstIndex(where: { $0 == value }) {
                    items[index] = ""
                    self.items.accept([.init(model: "", items: items)])
                    self.selectionCollectionView.reloadData()
                } else if let index = items.firstIndex(where: { $0.isEmpty }) {
                    items[index] = value
                    self.items.accept([.init(model: "", items: items)])
                    self.selectionCollectionView.reloadData()
                }
                
            }
            .disposed(by: self.disposeBag)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ConfirmSecretRecoveryPhraseViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === self.selectionCollectionView {
            let label = UILabel()
            label.text = self.listItemSelections.value[indexPath.row]
            label.font = .systemFont(ofSize: 14.0)
            let size = label.sizeThatFits(.init(width: CGFloat.infinity, height: 20))
            return .init(width: size.width + 32.0, height: 36)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return  8.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0
    }
}
