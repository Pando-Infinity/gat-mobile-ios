//
//  ListUserReactionViewController.swift
//  gat
//
//  Created by jujien on 11/6/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ListUserReactionViewController: BottomPopupViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    var presenter: ListUserReactionPresenter!
    
    var openProfile: ((Profile) -> Void)?
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        let attrs = NSMutableAttributedString(string: "Givers ", attributes: [.font: UIFont.systemFont(ofSize: 16.0, weight: .semibold), .foregroundColor: UIColor.navy])
        let attachment = NSTextAttachment()
        attachment.image = #imageLiteral(resourceName: "h")
        attrs.append(.init(attachment: attachment))
        self.titleLabel.attributedText = attrs
        self.presenter.subTitle.bind(to: self.subTitleLabel.rx.text).disposed(by: self.disposeBag)
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.collectionView.register(UserReactionCollectionViewCell.self, forCellWithReuseIdentifier: UserReactionCollectionViewCell.identifier)
        
        self.presenter.users.bind(to: self.collectionView.rx.items(cellIdentifier: UserReactionCollectionViewCell.identifier, cellType: UserReactionCollectionViewCell.self)) { (index, user, cell) in
            cell.user.accept(user)
        }
        .disposed(by: self.disposeBag)
        
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = .init(width: UIScreen.main.bounds.width, height: 60.0)
            layout.minimumInteritemSpacing = .zero
            layout.minimumLineSpacing = .zero
            layout.sectionInset = .zero 
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.collectionView.rx.modelSelected(UserReactionInfo.self).asObservable().subscribe (onNext: { [weak self] (user) in
            self?.dismiss(animated: true, completion: nil)
            self?.openProfile?(user.profile)
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
            self?.presenter.next()
        }).disposed(by: self.disposeBag)
        
        self.collectionView.rx.didScroll.withLatestFrom(Observable.just(self.collectionView).compactMap { $0 })
            .filter { (collectionView) -> Bool in
                let transition = collectionView.panGestureRecognizer.translation(in: collectionView.superview)
                guard collectionView.contentOffset.y == 0 else { return false }
                return transition.y > 100
            }
            .subscribe { [weak self] (_) in
                self?.presenter.refresh()
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
