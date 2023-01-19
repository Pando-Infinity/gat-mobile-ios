//
//  ExploreTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ExploreTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: HomeDelegate?
    fileprivate let disposeBag = DisposeBag()
    let explores: BehaviorSubject<[Exploration]> = .init(value: [.profile, .bookstop, .social,.GAT])
    let user = BehaviorRelay<UserPrivate?>(value: nil)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.data()
        self.backgroundColor = .white
        self.collectionView.backgroundColor = .white
        LanguageHelper.changeEvent.subscribe(onNext: { [weak self] (_) in
            self?.explores.onNext([.profile, .bookstop, .social, .GAT])
            }).disposed(by: disposeBag)
        self.setupUI()
    }
    
    fileprivate func data() {
        self.user.compactMap { $0 }.map { (userPrivate) -> [Exploration] in
            var explorations: [Exploration] = []
            if userPrivate.profile!.address.isEmpty || userPrivate.interestCategory.isEmpty || userPrivate.profile!.about.isEmpty || userPrivate.profile!.imageId.isEmpty || userPrivate.profile!.username.isEmpty || userPrivate.profile!.name.isEmpty {
                explorations.append(.profile)
            }
            if userPrivate.bookstops.first(where: { $0.id == Int(AppConfig.sharedConfig.config(item: "idGAT")!)! }) == nil  {
                
                explorations.append(.GAT)
            }
            if userPrivate.bookstops.isEmpty {
                explorations.append(.bookstop)
            } else {
                explorations.append(contentsOf: userPrivate.bookstops.map { Exploration.item($0) })
            }
            explorations.append(.social)
            if Session.shared.isAuthenticated {
                explorations.append(.createPost)
                explorations.append(.draftPost)
            }
            
            return explorations
        }.subscribe(onNext: self.explores.onNext).disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.registerCell()
        self.collectionView.delegate = self
        self.explores.bind(to: self.collectionView.rx.items(cellIdentifier: "exploreCollectionCell", cellType: ExploreCollectionViewCell.self)) { [weak self] (index, exploration, cell) in
                cell.delegate = self
                cell.setup(exploration: exploration)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func registerCell() {
        let nib = UINib(nibName: "ExploreCollectionViewCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "exploreCollectionCell")
    }
}

extension ExploreTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 2.2 - 8.0, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
    }
}

extension ExploreTableViewCell: ExploreCollectionCellDelegate {
    func showExplore(_ exploration: Exploration) {
        switch exploration {
        case .profile:
            if Repository<UserPrivate, UserPrivateObject>.shared.get() == nil {
                HandleError.default.loginAlert()
            } else {
                self.delegate?.showView(identifier: "showEditInfo", sender: nil)
            }
        case .bookstop:
            if Repository<UserPrivate, UserPrivateObject>.shared.get() == nil {
                HandleError.default.loginAlert()
            } else {
                self.delegate?.showView(identifier: ListBookstopOrganizationViewController.segueIdentifier, sender: nil)
            }
        case .social:
            UIApplication.shared.open(URL(string: "https://www.facebook.com/groups/congdonggat/")!, options: [:], completionHandler: nil)
        case .item(let bookstop):
            self.delegate?.showView(identifier: "showBookstopOrganization", sender: bookstop)
        case .GAT:
            if Session.shared.isAuthenticated {
                let storyboard = UIStoryboard(name: "BookstopOrganization", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "JoinBookstopViewController") as! JoinBookstopViewController
                vc.hidesBottomBarWhenPushed = true
                let bookStop = Bookstop()
                bookStop.id = Int(AppConfig.sharedConfig.config(item: "idGAT")!)!
                vc.bookstop.onNext(bookStop)
                vc.gotoBookstop = { bookstop in
                    self.delegate?.showView(identifier: BookstopOriganizationViewController.segueIdentifier, sender: bookstop)
                }
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            } else {
                let bookStop = Bookstop()
                bookStop.id = Int(AppConfig.sharedConfig.config(item: "idGAT")!)!
                self.delegate?.showView(identifier: BookstopOriganizationViewController.segueIdentifier, sender: bookStop)
            }
        case .draftPost:
            if Session.shared.isAuthenticated {
                let sb = UIStoryboard.init(name: "CreateArticle", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "DetailCollectionArticleVC") as! DetailCollectionArticleVC
                vc.receiveTypePost.onNext(.DraftPost)
                vc.hidesBottomBarWhenPushed = true
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            } else {
                HandleError.default.loginAlert()
            }
        case .createPost:
            let step = StepCreateArticleViewController()
            let user = Repository<UserPrivate, UserPrivateObject>.shared.get()
            let post = Post.init(title: "", intro: "", body: "", creator: .init(profile: (user?.profile)!, isFollowing: false))
            
            let storyboard = UIStoryboard(name: "CreateArticle", bundle: nil)
            let createArticle = storyboard.instantiateViewController(withIdentifier: CreatePostViewController.className) as! CreatePostViewController
            createArticle.presenter = SimpleCreatePostPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimpleCreatePostRouter(viewController: createArticle, provider: step))
            step.add(step: .init(controller: createArticle, direction: .forward))
            step.hidesBottomBarWhenPushed = true
            UIApplication.topViewController()?.navigationController?.pushViewController(step, animated: true)
        }
    }
    
    
}
