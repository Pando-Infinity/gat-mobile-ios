//
//  HomeViewController.swift
//  gat
//
//  Created by jujien on 12/11/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import XLPagerTabStrip

protocol HomeDelegate: class {
    func showView(identifier: String, sender: Any?)
}

struct NavigateHomeItem {
    var image: UIImage
    var title: String?
    var navigate: Navigate
    var segueIdentifier: String
    var newStatus: Bool

    enum Navigate: Int {
        case challange = 0
        case reviews = 1
        case gatup = 2
    }
}

enum UserPost: Int, CaseIterable {
    case userPost0 = 0
    case userPost1 = 1
}

enum HomeSectionItem: Int {
    case explore = 0
    case topBorowBook = 1
    case recommendPost = 2
    case hotWritter = 3
    case readPost = 4
    case trendingReview = 5
    case trendingPost = 6
}

class HomeViewController: UIViewController {
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var numberMessageView: UIView!
    @IBOutlet weak var numberMessageLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var seperateView: UIView!
    var tableView: UITableView = UITableView()
    private let refreshControl = UIRefreshControl()
    
    var sections: [HomeSectionItem] = [.explore, .topBorowBook]
    var selectedUser: Int = 0
    
    fileprivate var maskLayer: CAShapeLayer!
    fileprivate var cancelButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    fileprivate var post: [Post] = []
    fileprivate var hotWriter: [HotWriter] = []
    fileprivate var trendingReview: [Post] = []
    fileprivate var trendingPost: [Post] = []
    fileprivate var page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var showStatus: SearchState = .new
    fileprivate let disposeBag = DisposeBag()
    fileprivate let navigateItems: BehaviorSubject<[NavigateHomeItem]> = .init(value: [])

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getHotWriter()
        self.getAllArticle()
        self.getTrendingPost()
        self.setupUI()
        self.event()
        print("TOKEN:\((Session.shared.accessToken ?? ""))")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigateItems.onNext(
            [
                .init(image: #imageLiteral(resourceName: "tchallenge"), title: "CHALLENGE_TITLE".localized(), navigate: .challange, segueIdentifier: ListChallengeVC.segueIdentifier, newStatus: Session.shared.isAuthenticated && !AppConfig.sharedConfig.completPopupChallenge),
                .init(image: #imageLiteral(resourceName: "treview"), title: Gat.Text.ReviewExplore.TITLE.localized(), navigate: .reviews, segueIdentifier: ExploreReviewViewController.segueIdentifier, newStatus: false),
                .init(image: #imageLiteral(resourceName: "tgatup"), title: nil, navigate: .gatup, segueIdentifier: GatUpViewController.segueIdentifier, newStatus: false)
            ]
        )
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MessageService.shared.numberMessageNotRead().catchErrorJustReturn(0).subscribe(onNext: self.setupMessage(count:)).disposed(by: self.disposeBag)
    }
    
    // MARK: - Data
    fileprivate func getHotWriter(){
        PostService.shared.getHotWriter()
            .catchError { (error) -> Observable<[HotWriter]> in
                HandleError.default.showAlert(with: error)
                return Observable<[HotWriter]>.empty()
        }.subscribe(onNext: { [weak self] (hotwriter) in
            let arrFix4 = hotwriter.prefix(4)
            let newArr = Array(arrFix4)
            self?.hotWriter = newArr
            if !hotwriter.isEmpty {
                self?.sections.append(.hotWritter)
                self?.sections.sort(by: { $0.rawValue < $1.rawValue })
                self?.tableView.reloadData()
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func getAllArticle(){
        PostService.shared.getAllPost(pageNum: 1,pageSize: 2)
            .catchError { (error) -> Observable<[Post]> in
                HandleError.default.showAlert(with: error)
                return Observable<[Post]>.empty()
        }.subscribe(onNext: { [weak self] (posts) in
            self?.post = posts
            if !posts.isEmpty {
                self?.sections.append(.recommendPost)
                self?.sections.append(.readPost)
                self?.sections.sort(by: { $0.rawValue < $1.rawValue })
                self?.tableView.reloadData()
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func getTrendingPost(){
        PostService.shared.getTrending(pageNum: 1, pageSize: 10)
            .catchError { (error) -> Observable<[Post]> in
                HandleError.default.showAlert(with: error)
                return Observable<[Post]>.empty()
        }.subscribe(onNext: { [weak self] (posts) in
            self?.trendingPost = posts
            if !posts.isEmpty {
                self?.sections.append(.trendingReview)
//                self?.sections.append(.trendingPost)
                self?.sections.sort(by: { $0.rawValue < $1.rawValue })
                self?.tableView.reloadData()
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func giveDonate(profile: Profile, amount: Double) {
        do {
            try WalletService.shared.donate(user: profile, amount: amount)
            self.showConfirm(profile: profile, amount: amount)
        } catch {
            self.showDeposit()
        }
    }
        
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupNumberMessage()
        self.setupTipView()
        self.setupTableView()
        self.setupCollectionView()
        self.setupChallangePopup()
    }
    
    fileprivate func setupChallangePopup() {
        guard let gotoPage = GuidelineService.shared.gotoUserPage, gotoPage.complete, !AppConfig.sharedConfig.completPopupChallenge, Session.shared.isAuthenticated else { return }
        let duration: TimeInterval = 0.3
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.49)
        self.tabBarController!.view.addSubview(view)
        let imageView = UIImageView(image: #imageLiteral(resourceName: "challengepopup"))
        imageView.center = view.center
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        view.alpha = 0.0
        UIView.animate(withDuration: duration) {
            view.alpha = 1.0
        }
        
        view.rx.tapGesture().when(.recognized).subscribe(onNext: { (_) in
            UIView.animate(withDuration: duration, animations: {
                view.alpha = 0.0
            }) { (_) in
                AppConfig.sharedConfig.completPopupChallenge = true
                view.removeFromSuperview()
            }
        }).disposed(by: self.disposeBag)
        
        imageView.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                UIView.animate(withDuration: duration, animations: {
                    view.alpha = 0.0
                }) { (_) in
                    AppConfig.sharedConfig.completPopupChallenge = true
                    view.removeFromSuperview()
                    self?.performSegue(withIdentifier: ListChallengeVC.segueIdentifier, sender: nil)
                }
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTipView() {
        guard let user = Repository<UserPrivate, UserPrivateObject>.shared.get() else { return }
        guard let gotoPage = GuidelineService.shared.gotoUserPage, !gotoPage.complete else { return }
        self.configAlertTipView(user: user)
    }
    
    fileprivate func configButton(inTip view: EasyTipView) {
        let button = UIButton(frame: .init(origin: .init(x: view.frame.width - 65.0 - 16.0, y: 16.0 + UIApplication.shared.statusBarFrame.height), size: .init(width: 65.0, height: 30.0)))
        button.setAttributedTitle(.init(string: Gat.Text.CommonError.SKIP_ALERT_TITLE.localized(), attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 1)]), for: .normal)
        button.backgroundColor = .white
        button.cornerRadius(radius: 3.0)
        view.addSubview(button)
        
        button.rx.tap.subscribe(onNext: { (_) in
            UIView.animate(withDuration: view.preferences.animating.dismissDuration, delay: 0, usingSpringWithDamping: view.preferences.animating.springDamping, initialSpringVelocity: view.preferences.animating.springVelocity, options: [.curveEaseInOut], animations: {
                view.transform = view.preferences.animating.dismissTransform
                view.alpha = view.preferences.animating.dismissFinalAlpha
            }) { (finished) -> Void in
                view.removeFromSuperview()
                view.transform = CGAffineTransform.identity
            }
            GuidelineService.shared.cancel()
        }).disposed(by: self.disposeBag)
        self.cancelButton = button
    }
    
    fileprivate func configAlertTipView(user: UserPrivate) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        let title = String(format: Gat.Text.Guideline.HELLO_MESSAGE.localized(), user.profile!.name)
        let attributes = NSMutableAttributedString(string: title, attributes: [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1), .paragraphStyle: paragraphStyle])
        attributes.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: (title as NSString).range(of: user.profile!.name))
        let text = String(format: Gat.Text.Guideline.GO_TO_PROFILE_ALERT.localized(), Gat.Text.Guideline.PROFILE_PAGE.localized())
        let message = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1), .paragraphStyle: paragraphStyle])
        message.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)], range: (text as NSString).range(of: Gat.Text.Guideline.PROFILE_PAGE.localized()))
        attributes.append(message)
        
        var preferences = EasyTipView.Preferences()
        preferences.drawing.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        preferences.drawing.backgroundColorTip = .white
        preferences.drawing.shadowColor = #colorLiteral(red: 0.4705882353, green: 0.4705882353, blue: 0.4705882353, alpha: 1)
        preferences.drawing.shadowOpacity = 0.5
        preferences.drawing.arrowPosition = .bottom
        preferences.positioning.maxWidth = UIScreen.main.bounds.width - 32.0
        preferences.drawing.arrowHeight = 16.0
        preferences.animating.dismissOnTap = true
        guard let view = self.tabBarController?.tabBar.subviews.filter ({ $0.isKind(of: NSClassFromString("UITabBarButton") ?? UIView.self) })[2] else { return }
        
        let center = self.tabBarController!.tabBar.convert(view.center, to: self.tabBarController!.view)
        let clipPath = UIBezierPath(arcCenter: center, radius: (view.frame.height) / 2.0, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
        clipPath.append(.init(roundedRect: .init(x: UIScreen.main.bounds.width - 65.0 - 16.0, y: 16.0 + UIApplication.shared.statusBarFrame.height, width: 65.0, height: 30.0), cornerRadius: 3.0))
        let easyTip = EasyTipView(attributed: attributes, clipPath: clipPath, forcus: view, preferences: preferences, delegate: self)
        easyTip.show(withinSuperview: self.tabBarController!.view)
        self.configButton(inTip: easyTip)

    }
    
    fileprivate func setupTableView() {
        self.tableView.backgroundColor = .white
        self.tableView.separatorStyle = .none
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.seperateView.snp.bottom)
            maker.bottom.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
        }
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        self.registerCell()
    }
    
    @objc private func refreshData(){
        PostService.shared.getHotWriter()
            .catchError { (error) -> Observable<[HotWriter]> in
                HandleError.default.showAlert(with: error)
                return Observable<[HotWriter]>.empty()
        }.subscribe(onNext: { [weak self] (hotwriter) in
            let arrFix4 = hotwriter.prefix(4)
            let newArr = Array(arrFix4)
            self?.hotWriter = newArr
        }).disposed(by: self.disposeBag)
        
        PostService.shared.getAllPost(pageNum: 1,pageSize: 2)
            .catchError { (error) -> Observable<[Post]> in
                HandleError.default.showAlert(with: error)
                return Observable<[Post]>.empty()
        }.subscribe(onNext: { [weak self] (posts) in
            self?.post = posts
        }).disposed(by: self.disposeBag)
        
        PostService.shared.getTrending(pageNum: 1)
            .catchError { (error) -> Observable<[Post]> in
                HandleError.default.showAlert(with: error)
                return Observable<[Post]>.empty()
        }.subscribe(onNext: { [weak self] (posts) in
            self?.trendingPost = posts
        }).disposed(by: self.disposeBag)
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    fileprivate func registerCell() {
        self.registerExploreCell()
        self.registerTopBookBorrowCell()
        self.registerNewReviewCell()
        self.registerNearbyBookstopCell()
        self.registerSmallArticle()
        self.registerHotWriter()
        self.registerTrendingReview()
    }
    
    fileprivate func registerExploreCell() {
        let nib = UINib(nibName: "ExploreTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "exploreTableCell")
    }
    
    fileprivate func registerTopBookBorrowCell() {
        let bookNib = UINib(nibName: Gat.View.BOOK_TABLE_CELL, bundle: nil)
        self.tableView.register(bookNib, forCellReuseIdentifier: Gat.Cell.IDENTIFIER_BOOK)
    }
    
    fileprivate func registerNewReviewCell() {
        let nib = UINib(nibName: "ReviewTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "newReviewCell")
    }
    
    fileprivate func registerNearbyBookstopCell() {
        let nib = UINib(nibName: "NearbyBookstopTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "nearbyBookstopTableCell")
    }
    
    fileprivate func registerSmallArticle(){
        let nib = UINib(nibName: "SmallArticleTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "SmallArticleTableViewCell")
    }
    
    fileprivate func registerHotWriter(){
        let nib = UINib(nibName: "HotWriterTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "HotWriterTableViewCell")
    }
    
    fileprivate func registerTrendingReview(){
        let nib = UINib(nibName: "TrendingReviewTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "TrendingReviewTableViewCell")
    }
    
    fileprivate func setupCollectionView() {
        self.view.layoutIfNeeded()
        let height = self.collectionView.frame.height - 16.0
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .init(width: 100.0, height: height)
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 16.0
            layout.sectionInset = .init(top: 8.0, left: 16.0, bottom: 8.0, right: 16.0)
        }
        self.collectionView.backgroundColor = .white
        self.navigateItems
            .bind(to: self.collectionView.rx.items(cellIdentifier: NavigationItemHomeCollectionViewCell.identifier, cellType: NavigationItemHomeCollectionViewCell.self)) { (index, item, cell) in
                cell.navigateItem.accept(item)
                cell.heightCell = height 
        }.disposed(by: self.disposeBag)
    }

    fileprivate func setupNumberMessage() {
        self.numberMessageView.isHidden = true
        Observable.of(
            MessageService.shared.numberMessageNotRead().catchErrorJustReturn(0),
            MessageService.shared.listenNumberMessageNotRead().catchErrorJustReturn(0)
        )
            .merge()
            .subscribe(onNext: self.setupMessage(count:))
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupMessage(count: Int) {
        self.numberMessageView.isHidden = count == 0
        self.numberMessageLabel.text = "\(count)"
        self.numberMessageLabel.sizeToFit()
//        self.view.layoutIfNeeded()
        self.numberMessageView.cornerRadius(radius: self.numberMessageView.frame.height / 2.0)
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
    
    // MARK: - Event
    fileprivate func event() {
        self.scanButtonEvent()
        self.showMessageEvent()
        self.collectionViewEvent()
        LanguageHelper.changeEvent.subscribe(onNext: self.tableView.reloadData).disposed(by: self.disposeBag)
        LanguageHelper.changeEvent.subscribe(onNext: self.collectionView.reloadData).disposed(by: self.disposeBag)
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(NavigateHomeItem.self)
            .asObservable()
            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
            .subscribe(onNext: { (item, vc) in
                if item.navigate == .challange, !AppConfig.sharedConfig.completPopupChallenge, Session.shared.isAuthenticated {
                    vc.setupChallangePopup()
                } else if item.navigate == .reviews {
                    let sb = UIStoryboard.init(name: "CreateArticle", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "DetailCollectionArticleVC") as! DetailCollectionArticleVC
                    vc.receiveTypePost.onNext(.NewReview)
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    vc.performSegue(withIdentifier: item.segueIdentifier, sender: nil)
                }
                
            })
            .disposed(by: self.disposeBag)
        
    }

    
    fileprivate func scanButtonEvent() {
        self.scanButton
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.performSegue(withIdentifier: "showScanCode", sender: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showMessageEvent() {
        self.messageButton.rx.tap
            .do(onNext: { (_) in
                guard !Session.shared.isAuthenticated else { return }
                HandleError.default.loginAlert()
            })
            .filter { Session.shared.isAuthenticated }
            .subscribe(onNext: { [weak self] (_) in
                self?.performSegue(withIdentifier: Gat.Segue.SHOW_GROUP_MESSAGES_IDENTIFIER, sender: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showTopBookEvent(from view: UIView?) {
        view?.rx
            .tapGesture()
            .when(.recognized)
            .bind(onNext: { [weak self] (_) in
                self?.performSegue(withIdentifier: "showExploreBook", sender: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showDetailClvPost(from view:UIView?,type:TypeListArticle){
        view?.rx
        .tapGesture()
        .when(.recognized)
        .bind(onNext: { [weak self] (_) in
            let sb = UIStoryboard.init(name: "CreateArticle", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "DetailCollectionArticleVC") as! DetailCollectionArticleVC
            vc.receiveTypePost.onNext(type)
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        })
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func openCatergory(type: TypeListArticle, category: PostCategory) {
        let createArticle = UIStoryboard(name: "CreateArticle", bundle: nil)
        let vc = createArticle.instantiateViewController(withIdentifier: DetailCollectionArticleVC.className) as! DetailCollectionArticleVC
        vc.receiveTypePost.onNext(type)
        vc.titleScreen = category.title
        vc.arrCatergory.onNext([category.categoryId])
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
    
    func getViewControllerFromStorybroad(storybroadName: String,identifier: String) -> UIViewController{
        let storybroad = UIStoryboard(name: storybroadName, bundle: Bundle.main)
        return storybroad.instantiateViewController(withIdentifier: identifier)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == "showBookstopOrganization" {
            let vc = segue.destination as? BookstopOriganizationViewController
//            vc?.bookstop.onNext(sender as! Bookstop)
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        } else if segue.identifier == Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER {
            let vc = segue.destination as? BookStopViewController
            vc?.bookstop.onNext(sender as! Bookstop)
        } else if segue.identifier == PostDetailViewController.segueIdentifier {
            let vc = segue.destination as? PostDetailViewController
            vc?.presenter = SimplePostDetailPresenter(post: sender as! Post, imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: vc))
        }
    }

}

extension HomeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let item = self.sections[section]
        switch item {
        case .explore:
            return 1
        case .topBorowBook:
            return 1
        case .recommendPost:
            return self.post.count
        case .hotWritter:
            return 1
        case .readPost:
            return self.post.count
        case .trendingPost:
            return 1
        case .trendingReview:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.sections[indexPath.section]
        switch item {
        case .explore:
            let cell = tableView.dequeueReusableCell(withIdentifier: "exploreTableCell", for: indexPath) as! ExploreTableViewCell
            cell.delegate = self
            cell.user.accept(Session.shared.user)
            return cell
        case .topBorowBook:
            let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.IDENTIFIER_BOOK, for: indexPath) as! BookTableViewCell
            cell.delegate = self
            return cell
        case .recommendPost, .readPost:
            let cell = tableView.dequeueReusableCell(withIdentifier: SmallArticleTableViewCell.className, for: indexPath) as! SmallArticleTableViewCell
            cell.post.accept(self.post[indexPath.row])
            cell.selectionStyle = .none
            cell.showOption = { [weak self] post, success in
                if success == true {
                    guard let popupVC = self!.getViewControllerFromStorybroad(storybroadName: "CreateArticle", identifier: PopupForMoreArticleVC.className) as? PopupForMoreArticleVC else {return}
                    popupVC.post.accept(post)
                    popupVC.isHideDelete.onNext(1)
                    self!.present(popupVC, animated: true, completion: nil)
                    popupVC.isTapSave = { [weak self] success in
                        if success == true {
                            self?.dismiss(animated: true, completion: nil)
                            self!.post[indexPath.row].saving = !post.saving
                            self!.tableView.reloadData()
                            PostService.shared.saving(id: post.id, saving: post.saving)
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
                            let url = AppConfig.sharedConfig.get("web_url") + "articles/\(post.id)"
                            UIPasteboard.general.string = url
                            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            self?.present(controller, animated: true, completion: nil)
                        }
                    }
                }
            }
            cell.tapCellToOpenPostDetail = { [weak self] style,success in
                if success == true {
                    self?.showPostDetail(self!.post[indexPath.row], style: style)
                }
            }
            cell.tapUser = { [weak self] success in
                if success == true {
                    let cre = self!.post[indexPath.row].creator
                    let id = cre.profile.id
                    self?.openProfilePage(userId: id)
                }
            }
            
            cell.tapBook = { [weak self] success in
                if success == true {
                    let book = self!.post[indexPath.row].editionTags.first
                    if book != nil {
                        self?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: book)
                    }
                }
            }
            
            cell.tapCatergory = { [weak self] success in
                if success == true {
                    let cater = self!.post[indexPath.row].categories.first
                    if let catergory = cater {
                        self?.openCatergory(type: .Catergory, category: catergory)
                    }
                }
            }
            
            cell.likeEvent = { [weak self] reaction,count in
                PostService.shared.reaction(postId: self!.post[indexPath.row].id, reactionId: reaction.rawValue, reactionCount: count)
                    .catchError({ (error) -> Observable<()> in
                        
                        return .empty()
                    })
                    .subscribe(onNext: { (_) in
                        var post = self?.post[indexPath.row]
                        post?.summary.reactCount += count
                        let increase = (post?.userReaction.reactCount ?? 0) + count
                        post?.userReaction = .init(reactionId: reaction.rawValue, reactCount: increase)
                        self!.post[indexPath.row] = post!
                        self?.tableView.reloadData()
                        if let profile = post?.creator.profile {
                            self?.giveDonate(profile:profile, amount: Double(count))
                        }
                    })
                    .disposed(by: self!.disposeBag)
            }
            cell.giveAction = { [weak self] in
                let post = self?.post[indexPath.row]
                if let profile = post?.creator.profile {
                    self?.showGiveMore(profile: profile, amount: Double(post?.userReaction.reactCount ?? 0))
                }
            }
            return cell
        case .hotWritter:
            let cell = tableView.dequeueReusableCell(withIdentifier: HotWriterTableViewCell.className, for: indexPath) as! HotWriterTableViewCell
            cell.writer = self.hotWriter
            cell.viewPost1.hideMoreOption(hide: true)
            cell.viewPost2.hideMoreOption(hide: true)
            cell.userSelectedHandle = { [weak self] num in
                self?.selectedUser = num
                self?.tableView.reloadData()
            }
            cell.nameUser.accept(self.hotWriter[self.selectedUser].profile.name)
            cell.goMoreEvent = { [weak self] success in
                if success == true {
                    self?.openProfilePage(userId: (self?.hotWriter[cell.selectedUser].profile.id)!)
                }
            }
            let arrPost = self.hotWriter[self.selectedUser].articles
            if arrPost.count == 1 {
                cell.post1.accept(arrPost[0])
            } else if arrPost.count >= 2 {
                cell.post1.accept(arrPost[0])
                cell.post2.accept(arrPost[1])
            }
            cell.tapCellToOpenPostDetail = { [weak self] index, success in
                if success == true {
                    if index == 1 {
                        self?.showPostDetail(arrPost[0], style: .OpenNormal)
                    } else if index == 2 {
                        self?.showPostDetail(arrPost[1], style: .OpenNormal)
                    }
                }
            }
            return cell
        case .trendingPost, .trendingReview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TrendingReviewTableViewCell", for: indexPath) as! TrendingReviewTableViewCell
            cell.posts = self.trendingPost
            cell.tapCell = { [weak self] style,success in
                if success == true {
                    self?.showPostDetail(self!.trendingPost[cell.position], style: .OpenNormal)
                }
            }
            cell.tapUser = { [weak self] success in
                if success == true {
                    let cre = self!.trendingPost[cell.position].creator
                    let id = cre.profile.id
                    self?.openProfilePage(userId: id)
                }
            }
            
            cell.tapBook = { [weak self] success in
                if success == true {
                    let book = self!.trendingPost[cell.position].editionTags.first
                    if book != nil {
                        self?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER, sender: book)
                    }
                }
            }
            return cell
        }
    }
}

extension HomeViewController: UITableViewDelegate  {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = self.sections[indexPath.section]
        switch item {
        case .explore:
            return 140.0
        case .topBorowBook:
            return 250.0
        case .recommendPost:
            return 300.0
        case .hotWritter:
            return 560.0
        case .readPost:
            return 300.0
        case .trendingPost:
            return 400.0
        case .trendingReview:
            return 400.0
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = Bundle.main.loadNibNamed("HeaderSearch", owner: self, options: nil)?.first as? HeaderSearch
        let item = self.sections[section]
        switch item {
        case .explore:
            return nil
        case .topBorowBook:
            view?.titleLabel.text = Gat.Text.Home.TOP_BORROW_BOOK_TITLE.localized()
            view?.titleButton.text = Gat.Text.Home.MORE_TITLE.localized()
            view?.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
            view?.showView.isHidden = false
            self.showTopBookEvent(from: view)
            view?.titleLabel.textColor = .black
            view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
            view?.backgroundColor = .white
            return view
        case .recommendPost:
            view?.titleLabel.text = Gat.Text.Home.RECOMMEND_BY_GAT.localized()
            view?.titleButton.text = Gat.Text.Home.MORE_TITLE.localized()
            view?.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
            view?.showView.isHidden = false
            self.showDetailClvPost(from: view,type: .NewPost)
            view?.titleLabel.textColor = .black
            view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
            view?.backgroundColor = .white
            return view
        case .hotWritter:
            view?.titleLabel.text = Gat.Text.Home.HOT_WRITTERS_ON_GAT.localized()
            view?.titleButton.text = Gat.Text.Home.MORE_TITLE.localized()
            view?.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
            view?.showView.isHidden = true
            view?.backgroundColor = UIColor.white
            view?.titleLabel.textColor = .black
            view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
            return view
        case .readPost:
            view?.titleLabel.text = Gat.Text.Home.BASE_ON_READ_ARTICLE.localized()
            view?.titleButton.text = Gat.Text.Home.MORE_TITLE.localized()
            view?.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
            view?.showView.isHidden = false
            self.showDetailClvPost(from: view,type: .BasedOnReadPost)
            view?.titleLabel.textColor = .black
            view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
            view?.backgroundColor = .white
            return view
        case .trendingPost:
            view?.titleLabel.text = Gat.Text.Home.TRENDING_ARTICLE.localized()
            view?.titleButton.text = Gat.Text.Home.MORE_TITLE.localized()
            view?.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
            view?.showView.isHidden = false
            self.showDetailClvPost(from: view,type: .TrendingPost)
            view?.titleLabel.textColor = .black
            view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
            view?.backgroundColor = .white
            return view
        case .trendingReview:
            view?.titleLabel.text = Gat.Text.Home.TRENDING_REVIEW.localized()
            view?.titleButton.text = Gat.Text.Home.MORE_TITLE.localized()
            view?.forwardImageView.image = #imageLiteral(resourceName: "forward-icon").withRenderingMode(.alwaysTemplate)
            view?.showView.isHidden = false
            self.showDetailClvPost(from: view,type: .TrendingPost)
            view?.titleLabel.textColor = .black
            view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
            view?.backgroundColor = .white
            return view
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let item = self.sections[section]
        switch item {
        case .explore:
            return 0.0
        case .topBorowBook:
            return 35.0
        case .recommendPost:
            return 35.0
        case .hotWritter:
            return 35.0
        case .readPost:
            return 35.0
        case .trendingPost:
            return 35.0
        case .trendingReview:
            return 35.0
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= (tableView.contentSize.height - self.tableView.frame.height) {
            if transition.y < -70 {
                self.showStatus = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
            }
        }
    }
    
}

extension HomeViewController: HomeDelegate {
    func showView(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
}


extension HomeViewController: EasyTipViewDelegate {
    func easyTipViewDidDismiss(_ tipView: EasyTipView, forcus: Bool) {
        let guideline = GuidelineService.shared.gotoUserPage!
        GuidelineService.shared.complete(flow: guideline)
        guard forcus else { return }
        self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[2]
    }
}
