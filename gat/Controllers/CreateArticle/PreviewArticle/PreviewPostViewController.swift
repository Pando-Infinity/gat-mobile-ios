//
//  PreviewPostViewController.swift
//  gat
//
//  Created by jujien on 9/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa

class PreviewPostViewController: UIViewController {
    
    class var segueIdentifier: String { "showPreviewPost" }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var publishButton: UIButton!
    
    fileprivate var datasources: RxCollectionViewSectionedReloadDataSource<SectionModel<String, Any>>!
    fileprivate let disposeBag = DisposeBag()
    fileprivate let contentPostSize: BehaviorRelay<CGSize> = .init(value: UIScreen.main.bounds.size)
    
    var presenter: PreviewPostPresenter!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.presenter.loading.map { !$0 }.bind(to: self.view.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
        self.setupCollectionView()
        self.presenter.post.map{ $0.hashtags.count }.subscribe { (count) in
            count > 0 ? self.setupOverallHastagAndCatergoryFooter() : self.setupAddHashtagAndCategory()
        } onError: { (_) in
            
        } onCompleted: {
            
        } onDisposed: {
            
        }.disposed(by: self.disposeBag)
    }
    
    fileprivate func setupCollectionView() {
        self.presenter.post.map { $0.body }.filter { !$0.isEmpty }.distinctUntilChanged()
            .map { PostContentCollectionViewCell.size(content: $0, in: UIScreen.main.bounds.size) }
            .bind(onNext: self.contentPostSize.accept)
            .disposed(by: self.disposeBag)
        self.contentPostSize.distinctUntilChanged().bind { [weak self] (size) in
            self?.collectionView.reloadData()
        }
        .disposed(by: self.disposeBag)
        self.collectionView.delegate = self
        self.registerCell()
        self.bindingCollectionView()
    }
    
    fileprivate func registerCell() {
        self.collectionView.register(.init(nibName: TitlePostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: TitlePostCollectionViewCell.identifier)
        self.collectionView.register(.init(nibName: PostContentCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: PostContentCollectionViewCell.identifier)
        self.collectionView.register(.init(nibName: BookInPostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookInPostCollectionViewCell.identifier)
        self.collectionView.register(.init(nibName: OwnerPostCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: OwnerPostCollectionViewCell.identifier)
        
    }
    
    fileprivate func bindingCollectionView() {
        var bottomInset: CGFloat = .zero
        if #available(iOS 11.0, *) {
            bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
        } else {
        }
        self.collectionView.contentInset.bottom = 68.0 + bottomInset
        self.datasources = .init(configureCell: { [weak self] (datasource, collectionView, indexPath, item) -> UICollectionViewCell in
            if let post = item as? Post {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitlePostCollectionViewCell.identifier, for: indexPath) as! TitlePostCollectionViewCell
                cell.post.accept(post)
                if let size = self?.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath) {
                    cell.sizeCell.accept(size)
                }
                return cell
            } else if let content = item as? String {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostContentCollectionViewCell.identifier, for: indexPath) as! PostContentCollectionViewCell
                cell.downloadImage = self?.presenter.downloadImage(url: )
                cell.updateCollection = { [weak self] size in
                    self?.contentPostSize.accept(size)
                }
                if let size = self?.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath) {
                    cell.sizeCell.accept(size)
                }
                cell.content.accept(content)
                return cell
            } else if let books = item as? [BookInfo] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BookInPostCollectionViewCell.identifier, for: indexPath) as! BookInPostCollectionViewCell
                cell.books.accept(books)
                if let size = self?.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath) {
                    cell.sizeCell.accept(size)
                }
                return cell
            } else if let creator = item as? PostCreator {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OwnerPostCollectionViewCell.identifier, for: indexPath) as! OwnerPostCollectionViewCell
                cell.owner.accept(creator)
                if let size = self?.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath) {
                    cell.sizeCell.accept(size)
                }
                return cell
            }
            fatalError()
        })
        self.presenter.items.bind(to: self.collectionView.rx.items(dataSource: self.datasources)).disposed(by: self.disposeBag)
        
    }
    
    fileprivate func setupAddHashtagAndCategory() {
        let view = HashtagAndCategoryPostView(frame: .zero)
        self.view.addSubview(view)
        view.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            var bottomInset: CGFloat = .zero
            if #available(iOS 11.0, *) {
                bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
            } else {
            }
            maker.bottom.equalToSuperview()
            maker.height.equalTo(68.0 + bottomInset)

        }

        view.rx.tapGesture().when(.recognized).subscribe { [weak self] (_) in
            self?.presenter.addHashtagCategory()
        }
        .disposed(by: self.disposeBag)

    }
    
    fileprivate func setupOverallHastagAndCatergoryFooter(){
        guard let view = Bundle.main.loadNibNamed("OverallHastagAndCatergoryPostView", owner: self, options: nil)?.first as? OverallHastagAndCatergoryPost else {return}
        
        self.view.addSubview(view)
        self.presenter.post.subscribe { (post) in
            var tags: [PostTagItem] = []
            if let category = post.categories.first {
                tags = [.init(id: category.categoryId, title: category.title, image: #imageLiteral(resourceName: "combinedShapeCopy"))]
            }
            tags.append(contentsOf: post.hashtags.map { PostTagItem(id: $0.id, title: "#\($0.name)", image: nil) })
            view.items.accept(tags)
            view.tapEdit = { [weak self] success in
                if success == true {
                    self?.presenter.addHashtagCategory()
                }
            }
        } onError: { (_) in
            
        } onCompleted: {
            
        } onDisposed: {
            
        }.disposed(by: self.disposeBag)
        view.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            var bottomInset: CGFloat = .zero
            if #available(iOS 11.0, *) {
                bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
            } else {
            }
            maker.bottom.equalToSuperview()
            maker.height.equalTo(68.0 + bottomInset)

        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.publishEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.presenter.backScreen()
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func publishEvent() {
        self.publishButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.presenter.publishPost()
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

extension PreviewPostViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.presenter.item(indexPath: indexPath)
        if let post = item as? Post {
            return TitlePostCollectionViewCell.size(post: post, in: collectionView.frame.size)
        } else if item is String {
            return self.contentPostSize.value
        } else if item is [BookInfo] {
            return BookInPostCollectionViewCell.size(in: collectionView.frame.size)
        } else if let profile = item as? PostCreator {
            return OwnerPostCollectionViewCell.size(profile: profile, in: collectionView.frame.size)
        }
        return .zero 
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero 
    }
}
