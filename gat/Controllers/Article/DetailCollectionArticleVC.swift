//
//  DetailCollectionArticleVC.swift
//  gat
//
//  Created by macOS on 10/23/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

enum TypeListArticle: Int {
    case NewPost = 1
    case BasedOnReadPost = 2
    case DraftPost = 3
    case TrendingPost = 4
    case Catergory = 5
    case Hashtag = 6
    case NewReview = 7
}

class DetailCollectionArticleVC: UIViewController {
    
    @IBOutlet weak var tableViewPost:UITableView!
    @IBOutlet weak var viewHeader:UIView!
    @IBOutlet weak var backButton:UIButton!
    @IBOutlet weak var titleLabel:UILabel!
    
    var posts:BehaviorSubject<[Post]> = .init(value: [])
    var receiveTypePost:BehaviorSubject<TypeListArticle> = .init(value: .NewPost)
    var arrCatergory:BehaviorSubject<[Int]> = .init(value: [])
    var arrHashtag:BehaviorSubject<[Int]> = .init(value: [])
    var titleScreen:String = " "
    fileprivate var page: BehaviorSubject<Int> = .init(value: 1)
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.posts.onNext([])
        self.page.onNext(1)
        self.registerTbv()
        self.identifyArrPost()
        self.titleLabel.text = titleScreen
        self.dataTablePost()
        self.backButton.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.navigationController?.popViewController(animated: true)
            }).disposed(by: self.disposeBag)
    }
    
    func getViewControllerFromStorybroad(storybroadName: String,identifier: String) -> UIViewController{
        let storybroad = UIStoryboard(name: storybroadName, bundle: Bundle.main)
        return storybroad.instantiateViewController(withIdentifier: identifier)
    }
    
    func identifyArrPost(){
        self.receiveTypePost.subscribe(onNext: { (type) in
            switch type {
            case .NewPost:
                self.titleScreen = Gat.Text.Home.RECOMMEND_BY_GAT.localized()
                self.page.filter { _ in Status.reachable.value }
                    .flatMap { (page) -> Observable<[Post]> in
                        return PostService.shared.getAllPost(pageNum: page)
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
            case .BasedOnReadPost:
                self.titleScreen = Gat.Text.Home.BASE_ON_READ_ARTICLE.localized()
                self.page.filter { _ in Status.reachable.value }
                    .flatMap { (page) -> Observable<[Post]> in
                        return PostService.shared.getAllPost(pageNum: page)
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
            case .TrendingPost:
                self.titleScreen = Gat.Text.Home.TRENDING_REVIEW.localized()
                self.page.filter { _ in Status.reachable.value }
                    .flatMap { (page) -> Observable<[Post]> in
                        return PostService.shared.getTrending(pageNum: page)
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
            case .DraftPost:
                self.titleScreen = "DRAFT_ARTICLE".localized()
                self.page.filter { _ in Status.reachable.value }
                    .flatMap { (page) -> Observable<[Post]> in
                        return PostService.shared.getDraftPost(pageNum: page)
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
            case .Catergory:
                Observable.combineLatest(self.page.asObserver(), self.arrCatergory.asObserver())
                    .flatMap { page,arrCatergory -> Observable<[Post]> in
                        return PostService.shared.getCatergory(pageNum: page, arrCatergory: arrCatergory)
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
            case .Hashtag:
                Observable.combineLatest(self.page.asObserver(), self.arrHashtag.asObserver())
                    .flatMap { page,arrHashtag -> Observable<[Post]> in
                        return PostService.shared.getHashtag(pageNum: page, arrHashtag: arrHashtag)
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
            case .NewReview:
                self.titleScreen = "TITLE_REVIEWEXPLORE".localized()
                self.page.filter { _ in Status.reachable.value }
                    .flatMap { (page) -> Observable<[Post]> in
                        return PostService.shared.getAllNewReviewPost(pageNum: page)
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
        }).disposed(by: self.disposeBag)
    }
    
    func dataTablePost(){
        self.receiveTypePost.subscribe(onNext: { type in
            switch type {
            case .DraftPost:
                self.posts.bind(to: self.tableViewPost.rx.items(cellIdentifier: "SmallPostTbvCell",cellType: SmallPostTbvCell.self)) { [weak self] index,post,cell in
                    cell.post.accept(post)
                    cell.selectionStyle = .none
                    NotificationCenter.default.rx.notification(CompletePublishPostViewController.updatePost)
                    .compactMap { $0.object as? Post }
                    .do(onNext: { [weak self] (post) in
                        guard let posts = try? self?.posts.value() else { return }
                        guard var list = posts else {return}
                        guard let index = list.firstIndex(where: { $0.id == post.id }) else { return }
                        list.remove(at: index)
                        self!.posts.onNext(list)
                        })
                        .subscribe()
                        .disposed(by: self!.disposeBag)
                    
                    cell.tapCellToOpenPostDetail = { [weak self] style,success in
                        if success == true {
                            let step = StepCreateArticleViewController()
                            
                            let storyboard = UIStoryboard(name: "CreateArticle", bundle: nil)
                            let createArticle = storyboard.instantiateViewController(withIdentifier: CreatePostViewController.className) as! CreatePostViewController
                            createArticle.presenter = SimpleCreatePostPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimpleCreatePostRouter(viewController: createArticle, provider: step))
                            step.add(step: .init(controller: createArticle, direction: .forward))
                            step.hidesBottomBarWhenPushed = true
                            UIApplication.topViewController()?.navigationController?.pushViewController(step, animated: true)
                        }
                    }
                    cell.showOption = { [weak self] article, success in
                        if success == true {
                            guard let popupVC = self!.getViewControllerFromStorybroad(storybroadName: "CreateArticle", identifier: PopupForMoreArticleVC.className) as? PopupForMoreArticleVC else {return}
                            popupVC.post.accept(article)
                            popupVC.isHideDelete.onNext(2)
                            self!.present(popupVC, animated: true, completion: nil)
                            popupVC.isTapDelete = { [weak self] success in
                                if success == true {
                                    self?.dismiss(animated: true, completion: nil)
                                    PostService.shared.delete(postId: article.id)
                                    .catchError({ (error) -> Observable<()> in
                                        return .empty()
                                    }).subscribe(onNext: { (_) in
                                        var post = try? self!.posts.value()
                                        let index = post!.index(where: {$0.id == article.id})
                                        if let i = index {
                                            post!.remove(at: i)
                                            self?.posts.onNext(post!)
                                            self!.tableViewPost.reloadData()
                                        }
                                    }).disposed(by: self!.disposeBag)
                                }
                            }
                        }
                    }

                }.disposed(by: self.disposeBag)
            case .BasedOnReadPost,.Catergory,.Hashtag,.NewPost,.TrendingPost,.NewReview:
                self.posts.bind(to: self.tableViewPost.rx.items(cellIdentifier: "SmallArticleTableViewCell",cellType: SmallArticleTableViewCell.self)) { [weak self] index,post,cell in
                    cell.post.accept(post)
                    cell.selectionStyle = .none
                    cell.likeEvent = { [weak self] reaction,count in
                        PostService.shared.reaction(postId: post.id, reactionId: reaction.rawValue, reactionCount: count)
                            .catchError({ (error) -> Observable<()> in
                                return .empty()
                            })
                            .subscribe(onNext: { (_) in
                                var newPost = post
                                newPost.summary.reactCount += count
                                let increase = newPost.userReaction.reactCount + count
                                newPost.userReaction = .init(reactionId: reaction.rawValue, reactCount: increase)
                                var post = try? self!.posts.value()
                                post![index] = newPost
                                self?.posts.onNext(post!)
                                self?.tableViewPost.reloadData()
                                
                                self?.giveDonate(profile: newPost.creator.profile, amount: Double(count))
                            })
                            .disposed(by: self!.disposeBag)
                    }
                    cell.tapCellToOpenPostDetail = { [weak self] style,success in
                        if success == true {
                            self?.showPostDetail(post, style: style)
                        }
                    }
                    
                    cell.tapUser = { [weak self] success in
                        if success == true {
                            let cre = post.creator
                            let id = cre.profile.id
                            self?.openProfilePage(userId: id)
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
                    
                    cell.giveAction = { [weak self] in
                        self?.showGiveMore(profile: post.creator.profile, amount: Double(post.userReaction.reactCount))

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
                                    self?.posts.onNext(arti!)
                                    self!.tableViewPost.reloadData()
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
                            popupVC.isTapDelete = { [weak self] success in
                                if success == true {
                                    self?.dismiss(animated: true, completion: nil)
                                    PostService.shared.delete(postId: article.id)
                                    .catchError({ (error) -> Observable<()> in
                                        return .empty()
                                    }).subscribe(onNext: { (_) in
                                        var post = try? self!.posts.value()
                                        let index = post!.index(where: {$0.id == article.id})
                                        if let i = index {
                                            post!.remove(at: i)
                                            self?.posts.onNext(post!)
                                            self!.tableViewPost.reloadData()
                                        }
                                    }).disposed(by: self!.disposeBag)
                                }
                            }
                        }
                    }

                }.disposed(by: self.disposeBag)
            }
        }).disposed(by: self.disposeBag)
    }
    
    func registerTbv(){
        let nib = UINib(nibName: "SmallArticleTableViewCell", bundle: nil)
        self.tableViewPost.register(nib, forCellReuseIdentifier: "SmallArticleTableViewCell")
        
        let nibPostView = UINib(nibName: "SmallPostTbvCell", bundle: nil)
        self.tableViewPost.register(nibPostView, forCellReuseIdentifier: "SmallPostTbvCell")
        
        self.tableViewPost.delegate = self
        self.tableViewPost.backgroundColor = UIColor.white
        self.tableViewPost.separatorStyle = .none
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
        if self.tableViewPost.contentOffset.y >= (tableViewPost.contentSize.height - self.tableViewPost.frame.height) {
            if transition.y < -70 {
                self.page.onNext(((try? self.page.value()) ?? 0) + 1)
            }
        }
    }
    
    fileprivate func giveDonate(profile: Profile, amount: Double) {
        do {
            try WalletService.shared.donate(user: profile, amount: amount)
            self.showConfirm(profile: profile, amount: amount)
        } catch {
            self.showDeposit()
        }
    }
    
    fileprivate func showDeposit() {
        let failVC = FailGiveDonateViewController()
        failVC.depositHandler = {
            let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: WalletViewController.name) as! WalletViewController
            vc.currentIndex.accept(1)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        
        let sheetVC = SheetViewController(controller: failVC, sizes: [.fixed(176)])
        sheetVC.topCornersRadius = 16
        self.present(sheetVC, animated: true)
    }
    
    fileprivate func showGiveMore(profile: Profile, amount: Double) {
        let storyboard = UIStoryboard(name: "Give", bundle: nil)
        let giveMove = storyboard.instantiateViewController(withIdentifier: GiveMoreViewController.className) as! GiveMoreViewController
        giveMove.amountOptions.accept([10, 20, 50])
        giveMove.profile.accept(profile)
        giveMove.amount.accept(amount)
        giveMove.giveHandler =  { count in
            self.giveDonate(profile: profile, amount: count)
        }
        giveMove.modalTransitionStyle = .crossDissolve
        giveMove.modalPresentationStyle = .overCurrentContext
        self.present(giveMove, animated: true)
        
    }
    
    fileprivate func showConfirm(profile: Profile, amount: Double) {
        let confirmVC = GiveDonationConfirmViewController()
        confirmVC.profile.accept(profile)
        confirmVC.amount.accept(amount)
        confirmVC.showTransaction = {
            let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
            let walletVC = storyboard.instantiateViewController(withIdentifier: WalletViewController.name)
            self.navigationController?.pushViewController(walletVC, animated: true)
        }
        confirmVC.giveMoreHandler = { _ in
            self.showGiveMore(profile: profile, amount: amount)
        }
        let sheetVC = SheetViewController(controller: confirmVC, sizes: [.fixed(176)])
        sheetVC.topCornersRadius = 16
        self.present(sheetVC, animated: true)
    }
    
}

extension DetailCollectionArticleVC:UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var heightRow:CGFloat = 0
        self.receiveTypePost.subscribe(onNext: { (type) in
            switch type {
            case .BasedOnReadPost,.Catergory,.Hashtag,.NewPost,.TrendingPost,.NewReview:
                heightRow = 300.0
            case .DraftPost:
                heightRow = 250.0
            }
        }).disposed(by: self.disposeBag)
        return heightRow
    }
}


extension DetailCollectionArticleVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
