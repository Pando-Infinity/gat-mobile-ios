//
//  BookmarkPostVC.swift
//  gat
//
//  Created by macOS on 11/3/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class BookmarkPostVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate let posts: BehaviorSubject<[Post]> = .init(value: [])
    
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupTbv()
    }
    
    
    fileprivate func getData(){
        self.page.filter { _ in Status.reachable.value }
            .flatMap { (page) -> Observable<[Post]> in
                return PostService.shared.getSavedPost(pageNum: page)
                    .catchError { (error) -> Observable<[Post]> in
                        HandleError.default.showAlert(with: error)
                        return Observable<[Post]>.empty()
                }
        }
        .filter { !$0.isEmpty }
        .subscribe(onNext: { [weak self] (posts) in
            guard let value = try? self?.posts.value(), let page = try! self?.page.value() ,var list = value else { return }
            if page == 1 {
                list = posts
            } else {
                list.append(contentsOf: posts)
            }
            self?.posts.onNext(list)
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTbv(){
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = .white
        let nib = UINib(nibName: "SmallPostTbvCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "SmallPostTbvCell")
        self.posts
            .bind(to: self.tableView.rx.items(cellIdentifier: "SmallPostTbvCell", cellType: SmallPostTbvCell.self))
            { [weak self] (index, post, cell) in
                cell.selectionStyle = .none
                cell.post.accept(post)
                cell.tapCellToOpenPostDetail = { [weak self] style,success in
                    if success == true {
                        self?.showPostDetail(post, style: style)
                    }
                }
                
                cell.tapBook = { [weak self] success in
                    if success == true {
                        let book = post.editionTags.first
                        if book != nil {
                            self?.showBookDetail(book!)
                        }
                    }
                }
                
                cell.tapUser = { [weak self] success in
                    if success == true {
                        let cre = post.creator
                        let id = cre.profile.id
                        self?.openProfilePage(userId: id)
                    }
                }

                cell.showOption = { [weak self] article, success in
                    if success == true {
                        guard let popupVC = self!.getViewControllerFromStorybroad(storybroadName: "CreateArticle", identifier: PopupForMoreArticleVC.className) as? PopupForMoreArticleVC else {return}
                        popupVC.post.accept(article)
                        popupVC.isHideDelete.onNext(1)
                        self!.present(popupVC, animated: true, completion: nil)
                        popupVC.isTapSave = { [weak self] success in
                            if success == true {
                                var arti = try? self!.posts.value()
                                arti![index].saving = !article.saving
                                arti!.remove(at: index)
                                self?.posts.onNext(arti!)
                                self!.tableView.reloadData()
                                self?.dismiss(animated: true, completion: nil)
                                PostService.shared.saving(id: article.id, saving: article.saving)
                                    .catchError({ (error) -> Observable<()> in
                                        return .empty()
                                    })
                                    .subscribe()
                                    .disposed(by: self!.disposeBag)
                            }
                        }
                        popupVC.isTapShare = { [weak self] success in
                            if success == true {
                                self?.dismiss(animated: true, completion: nil)
                                let url = AppConfig.sharedConfig.get("web_url") + "articles/\(article.id)"
                                UIPasteboard.general.string = url
                                let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                self?.present(controller, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    
    func getViewControllerFromStorybroad(storybroadName: String,identifier: String) -> UIViewController{
        let storybroad = UIStoryboard(name: storybroadName, bundle: Bundle.main)
        return storybroad.instantiateViewController(withIdentifier: identifier)
    }
    
    fileprivate func showPostDetail(_ post:Post,style:OpenPostDetail){
        let storyboard = UIStoryboard(name: "PostDetail", bundle: nil)
        let postDetail = storyboard.instantiateViewController(withIdentifier: PostDetailViewController.className) as! PostDetailViewController
        postDetail.presenter = SimplePostDetailPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: postDetail))
        if style == .OpenNormal{
            postDetail.commentFirstResponder = false
        } else if style == .OpenWithComment{
            postDetail.commentFirstResponder = true
        }
        self.navigationController?.pushViewController(postDetail, animated: true)
    }
    
    fileprivate func showBookDetail(_ bookinfo:BookInfo){
        let storyboard = UIStoryboard(name: "BookDetail", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: BookDetailViewController.className) as! BookDetailViewController
        let book = BookInfo()
        book.editionId = bookinfo.editionId
        vc.bookInfo.onNext(book)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    fileprivate func openProfilePage(userId:Int){
        if Repository<UserPrivate, UserPrivateObject>.shared.get()?.id == userId {
            let user = UserPrivate()
            user.profile!.id = userId
            let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
            vc.isShowButton.onNext(true)
            vc.hidesBottomBarWhenPushed = true
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)

        } else {
            let user = UserPublic()
            user.profile = Profile()
            user.profile.id = userId
            let storyboard = UIStoryboard(name: "VistorProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: UserVistorViewController.className) as! UserVistorViewController
            vc.userPublic.onNext(user)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.height {
            if transition.y < -70 {
                self.page.onNext(((try? self.page.value()) ?? 0) + 1)
            }
        }
    }


}

extension BookmarkPostVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250.0
    }
}
