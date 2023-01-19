//
//  VisitorArticleVC.swift
//  gat
//
//  Created by macOS on 10/30/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class VisitorArticleVC: UIViewController {
    
    struct DefaultParam {
        var userId: Int?
        var pageNum: Int
        var pageSize: Int = 10
        var text: String = ""
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    var idUser:BehaviorSubject<Int?> = .init(value: nil)
    fileprivate let param: BehaviorRelay<DefaultParam> = .init(value: .init(userId: nil, pageNum: 1))
    fileprivate let posts: BehaviorSubject<[Post]> = .init(value: [])
    weak var userVistorController: UserVistorViewController?
    fileprivate let disposeBag = DisposeBag()

    override func viewDidAppear(_ animated: Bool) {
        self.searchTextField.attributedPlaceholder = .init(string: Gat.Text.SEARCH_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupTbv()
        self.hideKeyboardEvent()
        LanguageHelper.changeEvent.subscribe { (_) in
            self.tableView.reloadData()
        } onError: { (_) in
            
        } onCompleted: {
            
        } onDisposed: {
            
        }.disposed(by: self.disposeBag)

    }
    
    fileprivate func getData(){
        self.searchTextField.rx.text.orEmpty.withLatestFrom(self.idUser.asObserver()) { text,id -> DefaultParam in
            return .init(userId: id, pageNum: 1, text: text)
        }
        .subscribe(onNext: self.param.accept)
        .disposed(by: self.disposeBag)
        
        self.param
            .filter{ $0.userId != nil }
            .flatMap { (param) -> Observable<[Post]> in
                return PostService.shared.getUserPost(userId: param.userId!, pageNum: param.pageNum, title: param.text)
                    .catchError { (error) -> Observable<[Post]> in
                        HandleError.default.showAlert(with: error)
                        return Observable<[Post]>.empty()
                }
        }
        .filter { !$0.isEmpty }
        .subscribe(onNext: { [weak self] (posts) in
            guard let value = try? self?.posts.value(), let page = self?.param.value.pageNum ,var list = value else { return }
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
                
                cell.tapCatergory = { [weak self] success in
                    if success == true {
                        let cater = post.categories.first
                        if let catergory = cater {
                            self?.openCatergory(type: .Catergory, category: catergory)
                        }
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
        self.userVistorController?.navigationController?.pushViewController(postDetail, animated: true)
    }
    
    fileprivate func openCatergory(type: TypeListArticle, category: PostCategory) {
        let createArticle = UIStoryboard(name: "CreateArticle", bundle: nil)
        let vc = createArticle.instantiateViewController(withIdentifier: DetailCollectionArticleVC.className) as! DetailCollectionArticleVC
        vc.receiveTypePost.onNext(type)
        vc.titleScreen = category.title
        vc.arrCatergory.onNext([category.categoryId])
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    fileprivate func showBookDetail(_ bookinfo:BookInfo){
        let storyboard = UIStoryboard(name: "BookDetail", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: BookDetailViewController.className) as! BookDetailViewController
        let book = BookInfo()
        book.editionId = bookinfo.editionId
        vc.bookInfo.onNext(book)
        self.userVistorController?.navigationController?.pushViewController(vc, animated: true)
    }

    
    fileprivate func hideKeyboardEvent() {
        self.searchTextField.attributedPlaceholder = .init(string: Gat.Text.SEARCH_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        Observable.of(
            self.searchTextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
        )
            .merge()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchTextField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.height {
            if transition.y < -70 {
                var param = self.param.value
                param.pageNum += 1
                self.param.accept(param)
            }
        }
    }

}


extension VisitorArticleVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250.0
    }
}
