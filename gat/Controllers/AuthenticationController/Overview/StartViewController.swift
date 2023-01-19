//
//  StartViewController.swift
//  gat
//
//  Created by jujien on 5/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class StartViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var overviewButton: UIButton!
    @IBOutlet weak var pageControl: AdvancedPageControlView!
    
    fileprivate let images = [#imageLiteral(resourceName: "blackGroup114Group8Group3Mask"), #imageLiteral(resourceName: "backgroundShape2Group22Group146GiaoLUChiaSVGroup8Group11Group11CopyMask"), #imageLiteral(resourceName: "backgroundShape2Group22Group80NhNgReviewChNThGroup8Group11Group11CopyMask")]
    
    fileprivate let disposeBag = DisposeBag()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.signInButton.setTitle(Gat.Text.Login.LOGIN_TITLE.localized(), for: .normal)
        self.overviewButton.setTitle(Gat.Text.StartApp.OVERVIEW_APP_TITLE.localized(), for: .normal)
        self.signInButton.cornerRadius(radius: 4.0)
        self.setupCollectionView()
        self.setupPageControl()
    }
    
    fileprivate func setupPageControl() {
        self.pageControl.numberOfPages = self.images.count
        self.pageControl.drawer = ExtendedDotDrawer(numberOfPages: self.images.count, space: 4.0, raduis: 6.0, height: 6.0, width: 6.0, currentItem: 0, dotsColor: #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1), indicatorColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1), isBordered: false, borderColor: .clear, borderWidth: .zero)
    }
    
    fileprivate func setupCollectionView() {
        collectionView.backgroundColor = .white
        self.collectionView.register(UINib.init(nibName: ImageCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: ImageCollectionViewCell.identifier)
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.showsHorizontalScrollIndicator = false 
        
        self.view.layoutIfNeeded()
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = self.collectionView.frame.size
            layout.minimumInteritemSpacing = .zero
            layout.minimumLineSpacing = .zero
            layout.sectionInset = .zero
            layout.scrollDirection = .horizontal
        }
        
        Observable.just(self.images)
            .bind(to: self.collectionView.rx.items(cellIdentifier: ImageCollectionViewCell.identifier, cellType: ImageCollectionViewCell.self)) { [weak self] (index, image, cell) in
                cell.imageView.image = image
                cell.backgroundColor = .white
                cell.size = self?.collectionView.frame.size ?? .zero
                cell.imageView.contentMode = .scaleAspectFit
        }.disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.signInButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.performSegue(withIdentifier: LoginViewController.segueIdentifier, sender: nil)
        }).disposed(by: self.disposeBag)
        
        self.overviewButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                let window = vc.view.window
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: TabBarController.className)
                window?.rootViewController = vc
                window?.makeKeyAndVisible()
            }).disposed(by: self.disposeBag)
        
        self.collectionView.rx.didScroll.withLatestFrom(Observable.just(self.collectionView).compactMap { $0 })
            .subscribe(onNext: { [weak self] (collectionView) in
                self?.pageControl.setCurrentItem(offset: collectionView.contentOffset.x, width: collectionView.frame.width)
            }).disposed(by: self.disposeBag)
    }

}
