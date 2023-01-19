//
//  BookstopOriganizationViewController.swift
//  gat
//
//  Created by Vũ Kiên on 12/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import ExpandableLabel

class BookstopOriganizationViewController: UIViewController {
    
    class var segueIdentifier: String { return "showBookstopOrganization" }
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navView:UIView!
    @IBOutlet weak var totalView:UIView!
    @IBOutlet weak var titleNameBookstop:UILabel!

    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var presenter: BookstopOrganizationPresenter!
    
    fileprivate var datasource: RxCollectionViewSectionedReloadDataSource<SectionModel<BookstopOrganizationItem, Any>>!
    fileprivate var collapse = true
    
    fileprivate let requestStatus: BehaviorSubject<RequestBookstopStatus?> = .init(value: nil)
    fileprivate let disposeBag = DisposeBag()
    fileprivate var showGradient = true

    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupEditButton()
        self.setupCollectionView()
        self.clearNavBar()
        self.setupTitleNameBookstop()
    }
    
    fileprivate func setupEditButton() {
        self.editButton.isHidden = !Session.shared.isAuthenticated
    }
    
    fileprivate func setupTitleNameBookstop(){
        self.titleNameBookstop.textColor = .white
        self.titleNameBookstop.isHidden = true
    }
    
    fileprivate func setupCollectionView() {
        self.registerCell()
        self.collectionView.delegate = self
        self.collectionView.backgroundColor = .paleBlue
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        }
        let widthCell = UIScreen.main.bounds.width
        if let layout = self.collectionView.collectionViewLayout as? STCollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
            layout.minimumLineSpacing = 16.0
            layout.minimumInteritemSpacing = .zero
        }
        
        self.datasource = .init(configureCell: { [weak self] (datasource, collectionView, indexPath, element) -> UICollectionViewCell in
            if let bookstop = element as? Bookstop {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BookstopInfoCollectionViewCell.identifier, for: indexPath) as! BookstopInfoCollectionViewCell
                cell.collapse = self?.collapse ?? true
                cell.bookstop.accept(bookstop)
                cell.widthCell = widthCell
                cell.aboutLabel.delegate = self
                cell.showMember = { [weak self] in
                    self?.performSegue(withIdentifier: "showMember", sender: nil)
                }
                cell.showBook = { [weak self] in
                    self?.performSegue(withIdentifier: "showListBookInBookstop", sender: nil)
                }
                return cell
            } else if let tabs = element as? [NavigateHomeItem] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BookstopOrganizationTabCollectionViewCell.identifier, for: indexPath) as! BookstopOrganizationTabCollectionViewCell
                cell.navigateItems.accept(tabs)
                cell.widthCell = widthCell
                cell.showTab = self?.showTab(item:)
                return cell
            } else if let challenges = element as? [Challenge] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyChallangeOrganizationCollectionViewCell.identifier, for: indexPath) as! MyChallangeOrganizationCollectionViewCell
                cell.challenges.accept(challenges)
                cell.sizeCell = .init(width: widthCell, height: MyChallangeOrganizationCollectionViewCell.HEIGHT)
                cell.showChallengeDetail = { [weak self] challenge in
                    let sb = UIStoryboard.init(name: "ChallengeDetailView", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: ChallengeDetailVC.className) as! ChallengeDetailVC
                    vc.idChallenge = challenge.id
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
                return cell
            } else if let challenge = element as? Challenge {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChallengeOrganizationCollectionViewCell.identifier, for: indexPath) as! ChallengeOrganizationCollectionViewCell
                cell.widthCell = widthCell - 32.0
                cell.challenge.accept(challenge)
                return cell
            } else if let review = element as? Review {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReviewOrganizationCollectionViewCell.identifier, for: indexPath) as! ReviewOrganizationCollectionViewCell
                cell.widthCell = widthCell - 32.0
                cell.review.accept(review)
                cell.sendBookmark = self?.presenter.bookmark(review:)
                return cell
            } else if let post = element as? Post {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SmallArticleBookstopCollectionViewCell.identifier, for: indexPath) as! SmallArticleBookstopCollectionViewCell
                cell.sizeCell = SmallArticleBookstopCollectionViewCell.size(post: post, in: .init(width: collectionView.frame.width, height: SmallArticleBookstopCollectionViewCell.HEIGHT))
                cell.post.accept(post)
                cell.likeEvent = { [weak self] reaction,count in
                    self?.presenter.reactPost(post: post, reaction: reaction, count: count)
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
                                self?.dismiss(animated: true, completion: nil)
                                self?.presenter.bookmarkPost(post: article)
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

                
                return cell
            } else if let posts = element as? [Post] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PopularArticleBookstopOrgCollectionViewCell.identifier, for: indexPath) as! PopularArticleBookstopOrgCollectionViewCell
                
                cell.posts.accept(posts)
                cell.tapCell = { [weak self] style,success in
                    if success == true {
                        self?.showPostDetail(posts[cell.position], style: .OpenNormal)
                    }
                }
                cell.tapUser = { [weak self] success in
                    if success == true {
                        let cre = posts[cell.position].creator
                        let id = cre.profile.id
                        self?.openProfilePage(userId: id)
                    }
                }
                
                cell.tapBook = { [weak self] success in
                    if success == true {
                        let book = posts[cell.position].editionTags.first
                        if book != nil {
                            self?.showBookDetail(book!)
                        }
                    }
                }
                return cell
            }
            fatalError()
        }, configureSupplementaryView: { (datasource, collectionView, elementKind, indexPath) -> UICollectionReusableView in
            let model = datasource.sectionModels[indexPath.section].model
            if model == .info {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ListImageBookstopOrganizationCollectionReusableView.identifier, for: indexPath) as! ListImageBookstopOrganizationCollectionReusableView
                let bookstop = datasource.sectionModels[indexPath.section].items[0] as? Bookstop
                header.size = .init(width: widthCell, height: 231.0)
                header.bookstop.accept(bookstop)
                return header
            } else {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: HeaderBookstopOrganizationCollectionReusableView.identifier, for: indexPath) as! HeaderBookstopOrganizationCollectionReusableView
                if model == .myChallange {
                    self.setupHeaderTitle(label: header.titleLabel)
//                  header.titleLabel.text = "Thử thách của \(self.presenter.bookstop)"
                    header.imageView.image = #imageLiteral(resourceName: "list")
                    header.size = .init(width: widthCell, height: 59.0)
                    header.backgroundColor = .white
                } else if model == .review {
                    header.titleLabel.text = "MEMBER_POST_BOOKSTOP".localized()
                    header.imageView.image = nil
                    header.backgroundColor = .iceBlueTwo
                    header.size = .init(width: widthCell, height: 59.0)
                } else if model == .popularReview{
                    header.titleLabel.text = Gat.Text.Home.TRENDING_ARTICLE.localized()
                    header.imageView.image = #imageLiteral(resourceName: "invalidBookGradient")
                    header.backgroundColor = .iceBlueTwo
                    header.size = .init(width: widthCell, height: 59.0)
                } else {
                    header.titleLabel.text = nil
                    header.imageView.image = nil
                    header.size = .zero
                    header.backgroundColor = .white
                }
                return header
            }
        })
        
        self.presenter.items.bind(to: self.collectionView.rx.items(dataSource: self.datasource)).disposed(by: self.disposeBag)
        
        SwiftEventBus.onMainThread(self, name: RefreshChallengesEvent.EVENT_NAME) { [weak self] result in
            self?.presenter.getMyChallenge()
            self?.presenter.getChallenge()
        }
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
    
    fileprivate func setupHeaderTitle(label: UILabel) {
        self.presenter.bookstop.compactMap { $0.profile }.map { String(format: "CHALLENGE_OF_GATUP".localized(), $0.name) }.bind(to: label.rx.text).disposed(by: self.disposeBag)
    }
    
    fileprivate func registerCell() {
        self.collectionView.register(.init(nibName: ListImageBookstopOrganizationCollectionReusableView.className, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ListImageBookstopOrganizationCollectionReusableView.identifier)
        self.collectionView.register(UINib.init(nibName: BookstopInfoCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookstopInfoCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: BookstopOrganizationTabCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookstopOrganizationTabCollectionViewCell.identifier)
        self.collectionView.register(.init(nibName: MyChallangeOrganizationCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: MyChallangeOrganizationCollectionViewCell.identifier)
        self.collectionView.register(.init(nibName: ChallengeOrganizationCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: ChallengeOrganizationCollectionViewCell.identifier)
        self.collectionView.register(.init(nibName: ReviewOrganizationCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: ReviewOrganizationCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: SmallArticleBookstopCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: SmallArticleBookstopCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: PopularArticleBookstopOrgCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: PopularArticleBookstopOrgCollectionViewCell.identifier)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backButtonEvent()
        self.editButtonEvent()
        self.collectionView.rx.modelSelected(Any.self).compactMap{ $0 as? Challenge }.subscribe(onNext: { [weak self] (challenge) in
            let sb = UIStoryboard.init(name: "ChallengeDetailView", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: ChallengeDetailVC.className) as! ChallengeDetailVC
            vc.idChallenge = challenge.id
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: self.disposeBag)
        self.collectionView.rx.modelSelected(Any.self).compactMap{ $0 as? Review }.subscribe(onNext: { [weak self] (review) in
            let sb = UIStoryboard.init(name: "BookDetail", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: ReviewViewController.className) as! ReviewViewController
            vc.review.onNext(review)
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: self.disposeBag)

    }
    
    fileprivate func backButtonEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func editButtonEvent() {
        self.editButton.rx.tap.subscribe(onNext: self.presenter.editAction).disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showListBookInBookstop" {
            let vc = segue.destination as? BookstopOrganizationShelveController
            self.presenter.bookstop.subscribe(onNext: { (bookstop) in
                vc?.bookstop.onNext(bookstop)
            }).disposed(by: self.disposeBag)
        } else if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == "showMember" {
            let vc = segue.destination as? MemberBookstopViewController
            self.presenter.bookstop
                .subscribe(onNext: { (bookstop) in
                    vc?.bookstop.onNext(bookstop)
                })
                .disposed(by: self.disposeBag)
        } else if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            let userPublic = UserPublic()
            userPublic.profile = sender as! Profile
            vc?.userPublic.onNext(userPublic)
        } else if segue.identifier == ActivityBookstopOrganizationViewController.segueIdentifier {
            let vc = segue.destination as? ActivityBookstopOrganizationViewController
            self.presenter.bookstop
            .subscribe(onNext: { (bookstop) in
                vc?.bookstop.accept(bookstop)
            })
            .disposed(by: self.disposeBag)
        } else if segue.identifier == ListChallengeVC.segueIdentifier {
            let vc = segue.destination as? ListChallengeVC
            self.presenter.bookstop
                .subscribe(onNext: { (bookstop) in
                    vc?.bookstop.onNext(bookstop)
                })
                .disposed(by: self.disposeBag)
            vc?.flagChallengeModel = 2
        }
     }
    
    fileprivate func showTab(item: NavigateHomeItem) {
        self.performSegue(withIdentifier: item.segueIdentifier, sender: nil)
    }
    
    fileprivate func clearNavBar(){
        self.totalView.backgroundColor = .clear
        self.navigationController?.navigationBar.tintColor = .clear
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = self.navigationController?.navigationBar.frame.height ?? 0.0
        let navHeight = UIApplication.shared.statusBarFrame.height + height
        let y = scrollView.contentOffset.y + navHeight
        if y >= 213.0 {
           self.totalView.isHidden = false
            self.navigationController?.navigationBar.isHidden = false
            self.totalView.backgroundColor = UIColor.init(red: 90.0/255.0, green: 164/255.0, blue: 204.0/255.0, alpha: 1.0)
            self.titleNameBookstop.isHidden = false
            self.presenter.bookstop
            .subscribe(onNext: { (bookstop) in
                guard let name = bookstop.profile?.name else {return}
                self.titleNameBookstop.text = "\(name)"
            })
        }
        else {
            self.titleNameBookstop.isHidden = true
            self.totalView.backgroundColor = .clear
            self.navigationController?.navigationBar.tintColor = .clear
        }
    }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.collectionView.contentOffset.y >= (collectionView.contentSize.height - self.collectionView.frame.height) {
            if transition.y < -100 {
                presenter.loadMore()
            }
        }
    }
}

extension BookstopOriganizationViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.presenter.item(indexPath: indexPath)
        if let bookstop = item as? Bookstop {
            return BookstopInfoCollectionViewCell.size(bookstop: bookstop, collapse: self.collapse, in: collectionView.frame.size)
        } else if item is [NavigateHomeItem] {
            return .init(width: collectionView.frame.width, height: BookstopOrganizationTabCollectionViewCell.HEIGHT)
        } else if item is [Challenge] {
            return .init(width: collectionView.frame.width, height: MyChallangeOrganizationCollectionViewCell.HEIGHT)
        } else if let challenge = item as? Challenge {
            return ChallengeOrganizationCollectionViewCell.size(challenge: challenge, in: collectionView.bounds.size)
        } else if let review = item as? Review {
            return ReviewOrganizationCollectionViewCell.size(review: review, in: collectionView.bounds.size)
        } else if let post = item as? Post {
            return SmallArticleBookstopCollectionViewCell.size(post: post, in: .init(width: collectionView.frame.width, height: SmallArticleBookstopCollectionViewCell.HEIGHT))
        } else if let posts = item as? [Post], !posts.isEmpty {
            let size = posts.map { MediumArticleBookstopCollectionViewCell.size(post: $0, in: .init(width: collectionView.frame.width * 0.8, height: .infinity)) }.max(by: { $0.height < $1.height })!
            return .init(width: collectionView.frame.width, height: size.height + 52.0)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let item = self.presenter.section(index: section)
        switch item {
        case .review: return 4.0
        case .challenge: return 8.0
        default: return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let item = self.presenter.section(index: section)
        switch item {
        case .review: return .init(top: 0.0, left: 16.0, bottom: 4.0, right: 16.0)
        case .challenge: return .init(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        default: return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let item = self.presenter.section(index: section)
        if item == .myChallange || item == .review || item == .popularReview {
            return .init(width: collectionView.frame.width, height: HeaderBookstopOrganizationCollectionReusableView.HEIGHT)
        } else if item == .info {
            return .init(width: collectionView.frame.width, height: ListImageBookstopOrganizationCollectionReusableView.HEIGHT)
        }
        return .zero
    }
}

extension BookstopOriganizationViewController: ExpandableLabelDelegate {
    func willExpandLabel(_ label: ExpandableLabel) {
        self.collapse = false

    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        self.collectionView.reloadData()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        self.collapse = true
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        self.collectionView.reloadData()
    }
    
    
}

extension BookstopOriganizationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
