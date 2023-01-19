//
//  SelectCategoryPostViewController.swift
//  gat
//
//  Created by jujien on 9/3/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SelectCategoryPostViewController: UIViewController {
    
    class var segueIdentifier: String { "showSelectCategoryPost" }
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchContainerView: UIView!
    
    weak var provider: StepCreateArticleProvider?
    var presenter: SelectCategoryPostPresenter!
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = "REMIND_SELECT_ARTICLES_TYPE_TITLE".localized()
        self.searchTextField.attributedPlaceholder = .init(string: Gat.Text.SEARCH_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.searchContainerView.cornerRadius(radius: 4.0)
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.register(PostCategoryCollectionViewCell.self, forCellWithReuseIdentifier: PostCategoryCollectionViewCell.identifier)
        self.presenter.categories.bind(to: self.collectionView.rx.items(cellIdentifier: PostCategoryCollectionViewCell.identifier, cellType: PostCategoryCollectionViewCell.self)) { [weak self] (index, item, cell) in
            cell.item.accept(item)
            cell.itemSelected.accept(self?.presenter.selected.value?.categoryId == item.categoryId)
            if let collectionView = self?.collectionView {
                cell.sizeCell = self?.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: .init(row: index, section: 0)) ?? .zero
            }
        }.disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.collectionViewEvent()
        self.searchEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.subscribe(onNext: { (_) in
            self.provider?.popStep()
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func searchEvent() {
        self.searchTextField.rx.text.orEmpty
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .bind(onNext: self.presenter.search(title:))
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(PostCategory.self).subscribe(onNext: { [weak self] (item) in
            self?.presenter.selected.accept(item)
            self?.collectionView.reloadData()
            self?.provider?.popStep()
        })
            .disposed(by: self.disposeBag)
        
        self.collectionView.rx.willBeginDecelerating.asObservable().compactMap { [weak self] _ in self?.collectionView }
            .filter({ (collectionView) -> Bool in
                return collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.frame.height)
            })
            .filter({ (collectionView) -> Bool in
                let translation = collectionView.panGestureRecognizer.translation(in: collectionView.superview)
                return translation.y < -70.0
            })
        .subscribe(onNext: { [weak self] (_) in
            // call api this here
            self?.presenter.next()
        }).disposed(by: self.disposeBag)
    }
}

extension SelectCategoryPostViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width, height: 44.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}
