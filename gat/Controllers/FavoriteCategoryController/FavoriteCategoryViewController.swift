//
//  FavoriteCategoryViewController.swift
//  gat
//
//  Created by HungTran on 3/6/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAnalytics

protocol FavouriteCategoryDelegate: class {
    func update(category: [Category])
}

class FavoriteCategoryViewController: UIViewController {
    //MARK: - UI Properties
    @IBOutlet weak var favoriteCategoryView: UICollectionView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    weak var delegate: FavouriteCategoryDelegate?
    let isEditingFavourite = BehaviorSubject<Bool>(value: true)
    let selectedCategory = BehaviorSubject<[Category]>(value: [])
    fileprivate let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getFavouriteCategory()
        self.request()
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    // MARK: - Data
    fileprivate func getFavouriteCategory() {
        self.isEditingFavourite
            .filter { !$0 }
            .flatMap { _ in
                Repository<UserPrivate, UserPrivateObject>
                    .shared
                    .getFirst()
            }
            .map { $0.interestCategory }
            .subscribe(onNext: { [weak self] (categories) in
                self?.selectedCategory.onNext(categories)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Send Request
    fileprivate func request() {
        self.submitButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.isEditingFavourite)
            .filter { !$0 }
            .withLatestFrom(self.selectedCategory)
            .flatMap { (categories) -> Observable<UserPrivate> in
                return Repository<UserPrivate, UserPrivateObject>
                    .shared
                    .getFirst()
                    .do(onNext: { (userPrivate) in
                        userPrivate.interestCategory = categories
                    })
            }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.view.isUserInteractionEnabled = false
            })
            .flatMap { [weak self] (userPrivate) -> Observable<UserPrivate> in
                return UserNetworkService
                    .shared
                    .updateInfo(user: userPrivate)
                    .catchError({ [weak self] (error) -> Observable<()> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self?.view.isUserInteractionEnabled = true
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
                    .map { _ in userPrivate }
            }
            .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.view.isUserInteractionEnabled = true
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = Gat.Text.FavouriteCategory.FAVOURITE_CATEGORY_TITLE.localized()
        self.setupCollectionView()
        self.setupSubmitButton()
    }
    
    fileprivate func setupCollectionView() {
        self.favoriteCategoryView.delegate = self
        Observable<[Category]>
            .just(Category.all)
            .bind(to: self.favoriteCategoryView.rx.items(cellIdentifier: "favorite_category_item", cellType: CategoryCollectionViewCell.self)) { [weak self] (index, category, cell) in
                if let value = try? self?.selectedCategory.value(), let selected = value {
                    cell.setup(category: category, isSelected: selected.contains(where: {$0.id == category.id}))
                } else {
                    cell.setup(category: category)
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSubmitButton() {
        self.submitButton.setTitle(Gat.Text.FavouriteCategory.SAVE_TITLE.localized(), for: .normal)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.collectionViewEvent()
        self.saveCategoryEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func collectionViewEvent() {
        self.favoriteCategoryView
            .rx
            .modelSelected(Category.self)
            .bind { [weak self] (category) in
                guard let value = try? self?.selectedCategory.value(), var selected = value else {
                    return
                }
                if let index = selected.index(where: {$0.id == category.id}) {
                    selected.remove(at: index)
                } else {
                    selected.append(category)
                }
                self?.selectedCategory.onNext(selected)
                self?.favoriteCategoryView.reloadData()
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func saveCategoryEvent() {
        self.submitButton
            .rx
            .controlEvent(.touchUpInside)
            .flatMap { [weak self] (_) -> Observable<([Category], Bool)> in
                return Observable<([Category], Bool)>.combineLatest(self?.selectedCategory.asObservable() ?? Observable.empty(), self?.isEditingFavourite.asObservable() ?? Observable.empty(), resultSelector: {($0, $1)})
            }
            .filter { (_, isEditing) in  isEditing }
            .map { (selected, _ ) in selected }
            .bind { [weak self] (selected) in
                self?.delegate?.update(category: selected)
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: self.disposeBag)
    }
    
}

extension FavoriteCategoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = self.view.frame.width / 3.0 - 3.0 * 5.0
        let cellHeight = 139.0/110.0 * cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

extension FavoriteCategoryViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
