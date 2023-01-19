//
//  ChallengeDetailNew.swift
//  gat
//
//  Created by Hung Nguyen on 2/1/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import SnapKit
import RxSwift
import RxCocoa
import FBSDKShareKit
import FBSDKShareKit

enum ChallengeItemDetail:Int, Comparable{
    case content = 0
    case activeMember = 1
    case filter = 2
    case news = 3
    
    static func < (lhs: ChallengeItemDetail, rhs: ChallengeItemDetail) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

class ChallengeDetailVC: BaseViewController {
    
    override class var storyboardName: String {return "ChallengeDetailView"}
    
    @IBOutlet weak var lbTitleBar: UILabel!
    
    @IBOutlet weak var tableViewContent: UITableView!
    @IBOutlet weak var ivCover: UIImageView!
    @IBOutlet weak var vFade: UIView!
    @IBOutlet weak var completeImageView: UIImageView!
    
    @IBOutlet weak var coverHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressHighConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressLowConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var vJoinChallenge: UIView!
    @IBOutlet weak var vUpdateChallenge: UIView!
    
    @IBOutlet weak var btnJoinChallenge: UIButton!
    @IBOutlet weak var btnUpdateProgress: UIButton!
    
    @IBOutlet weak var lbCurrentProgress: UILabel!
    @IBOutlet weak var lbTimeRemain: UILabel!
    
    private var viewModelChallenge: ChallengeViewModel!
    private var viewModelMembers: ActiveMembersViewModel!
    
    private var challenge: Challenge?
    private var activities: [CActivity] = []
    private var nibContent: UINib!
    private var nibActiveMember: UINib?
    private var nibFilter:UINib?
    private let joinChallenge = PublishSubject<Int>()
    private let getDataMembers = PublishSubject<Int>()
    private let getChallenge = PublishSubject<Int>()
    private let getActivities = BehaviorRelay<ChallengeViewModel.ActivityParam?>(value: nil)
    fileprivate var page: BehaviorSubject<Int> = .init(value: 1)
    private var reviews: [Review] = []
    
//  let isInviteButtonTaped: BehaviorSubject<Bool> = .init(value: false)
    
    private var activeMembers: [LeaderBoard] = []
    private var listPost: [Post] = []
    private var isHaveActiveMember: Bool = false
    
    var idChallenge: Int = 0
    
    private var blurAnimator: UIViewPropertyAnimator!
    private var firstCellHeight: CGFloat = 320
    private let coverViewMaxHeight: CGFloat = 470
    private let coverViewMinHeight: CGFloat = 140 + UIApplication.shared.statusBarFrame.height //44
    // Use this to check after first time add height for cell then should add again
    private var isDoneAddHeight: Bool = false
    //private var coverViewMinHeight: CGFloat = 80 + UIApplication.shared.statusBarFrame.height
    
    let useCase = Application.shared.networkUseCaseProvider
    var input: ChallengeViewModel.Input!
    
    var section:[ChallengeItemDetail] = [.content,.activeMember,.filter,.news]
    
    
    var selectedItem: Item = .article
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init view
        //self.vFade.isHidden = true
        self.vFade.backgroundColor = Colors.grayTrans20
        
        btnJoinChallenge.setTitle("BUTTON_JOIN_CHALLENGE".localized(), for: .normal)
        btnUpdateProgress.setTitle("UPDATE_PROGRESS".localized(), for: .normal)
        
        initTableView()
        // Hide all views about join and update progress
        vJoinChallenge.isHidden = true
        vUpdateChallenge.isHidden = true
        lbTitleBar.isHidden = true
        self.getReviews()
        
        self.completeImageView.isHidden = true
        self.progressLowConstraint.priority = .defaultLow
        self.progressHighConstraint.priority = .defaultHigh
        
        // Bind ViewModels
        
        // Set On EventBus listener
        setOnUpdateCellHeightEvent()
        onJoinEvent()
        onOpenMembersEvent()
        
        self.section.sort(by: { $0.rawValue < $1.rawValue })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        bindViewModelChallenge()
        bindViewModelMembers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.disposeBag = DisposeBag()
    }
    
    private func initTableView() {
        nibContent = UINib.init(nibName: "ChallengeContentCell", bundle: nil)
        self.tableViewContent.register(nibContent, forCellReuseIdentifier: "ChallengeContentCell")
        
        nibActiveMember = UINib.init(nibName: "ActiveMemberCollectionCell", bundle: nil)
        self.tableViewContent.register(nibActiveMember, forCellReuseIdentifier: "ActiveMemberCollectionCell")
        
        nibFilter = UINib.init(nibName: "FilterTableViewCell", bundle: nil)
        self.tableViewContent.register(nibFilter, forCellReuseIdentifier: "FilterTableViewCell")
        
        let nibNews = UINib.init(nibName: "ChallengeNewsCell", bundle: nil)
        self.tableViewContent.register(nibNews, forCellReuseIdentifier: "ChallengeNewsCell")

        let nibArticle = UINib.init(nibName: "SmallArticleTableViewCell", bundle: nil)
        self.tableViewContent.register(nibArticle, forCellReuseIdentifier: "SmallArticleTableViewCell")
        
        
        // Set delegate
        tableViewContent.delegate = self
        tableViewContent.dataSource = self
        tableViewContent.allowsSelection = false
        
        tableViewContent.rowHeight = UITableView.automaticDimension
        tableViewContent.estimatedRowHeight = firstCellHeight
        
        tableViewContent.backgroundColor = Colors.transparent
        tableViewContent.contentInset = UIEdgeInsets(top: 350, left: 0, bottom: 0, right: 0)
        tableViewContent.separatorStyle = .none
    }
    
    private func bindViewModelChallenge() {
        viewModelChallenge = ChallengeViewModel(
            useCaseChallenge: useCase.makeChallengeUseCase(),
            useCaseActivities: useCase.makeCActivitiesUseCase(),
            useCaseJoinIn: useCase.makeJoinChallengeUseCase()
        )
        
        input = ChallengeViewModel.Input(
            getChallenge: self.getChallenge,
            getActivities: self.getActivities,
            joinChallenge: self.joinChallenge
        )
        
        let output = viewModelChallenge.transform(input)
        
        output.challenge
            .subscribe(onNext: { [weak self] result in
                //guard it = result else { return }
                self?.lbTitleBar.text = result.title
                // Update cell height by height of title challenge
                let height = ChallengeContentCell.getTitleHeight(lbWidth: self?.view.frame.width ?? 0, text: result.title, lines: 0)
                if height > 22 && !self!.isDoneAddHeight {
                    print("Add height called")
                    let heightOver = height - 22
                    self?.firstCellHeight += heightOver
                    self?.isDoneAddHeight = true
                }
                
                self?.ivCover.setImage(imageId: result.imageCover)
                self?.challenge = result
                self?.getListPost(challenge: result)
//                self?.section.sort(by: { $0.rawValue < $1.rawValue })
//                self?.section.append(.content)
//                self?.section.append(.news)
                if !(self?.challenge?.targetTypeId == 2 || self?.challenge?.targetTypeId == 4) {
                    self?.section.removeAll(where: {$0 == .filter})
                    self?.section.sort(by: { $0.rawValue < $1.rawValue })
                    self?.selectedItem = .activity
                }
                self?.tableViewContent.reloadData()
                
                self?.showHideViewUpdateProgress(challenge: result)
                self?.handleTimeToJoinChallenge(challenge: result)
            }).disposed(by: disposeBag)
        
        output.activities
            .subscribe(onNext: { [weak self] result in
                guard let it = result.activities, let param = self?.getActivities.value, var activities = self?.activities else { return }
                if param.pageNum == 1 {
                    activities = it
                } else {
                    activities.append(contentsOf: it)
                }
                
                self?.activities = activities
                self?.tableViewContent.reloadData()
            }).disposed(by: disposeBag)
        
        output.joinResult
            .subscribe(onNext: {
                print("Mapped Sequence: \($0)")
                ToastView.makeToast("MESSAGE_JOIN_CHALLENGE_SUCCESS".localized())
                SwiftEventBus.post(RefreshChallengesEvent.EVENT_NAME)
                self.getChallenge.onNext(self.idChallenge)
                //self.bindViewModelChallenge()
            }).disposed(by: disposeBag)
        
        output.error
            .drive(rx.error)
            .disposed(by: disposeBag)
        
        self.getChallenge.onNext(idChallenge)
        self.getActivities.accept(.init(challengeId: self.idChallenge, pageNum: 1))
    }
    
    private func handleTimeToJoinChallenge(challenge: Challenge){
        let timeStartChallenge = challenge.startDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let currentDate = dateFormatter.string(from: Date())
        print("CURRENT: \(currentDate) STARTDATE: \(timeStartChallenge)")
        if currentDate < timeStartChallenge {
            btnJoinChallenge.isUserInteractionEnabled = false
            btnJoinChallenge.backgroundColor = .gray
        }
        
        
    }
    
    private func getListPost(challenge: Challenge){
        PostService.shared.getListPostChallenge(challenge: challenge).subscribe(onNext: { (arrPost) in
            self.listPost = arrPost
            self.tableViewContent.reloadData()
        }).disposed(by: self.disposeBag)
    }
    
    private func showHideViewUpdateProgress(challenge: Challenge) {
        // Check if challenge is not expired
        // then check show or hide view update process
        //not expired
        if !TimeUtils.isExpiredNow(challenge.endDate) {
            print("Time is expired date: \(challenge.endDate)")
            // Show hide view update progress
            if let it = challenge.challengeProgress, let summary = challenge.challengeSummary {
                if it.targetNumber > 0 && it.progress >= it.targetNumber {
                    // Show popup complete challenge
                    self.vUpdateChallenge.isHidden = false
                    self.lbCurrentProgress.textColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
                    self.progressLowConstraint.priority = .defaultHigh
                    self.progressHighConstraint.priority = .defaultLow
                    self.completeImageView.isHidden = false
                    
                    if challenge.challengeModeId == 1 {
                        self.lbCurrentProgress.text = String(
                            format: "FORMAT_CURRENT_PROGRESS_OF_CHALLENGE".localized(),
                            it.progress,
                            it.targetNumber
                        )
                    } else {
                        self.lbCurrentProgress.text = String(
                            format: "FORMAT_CURRENT_PROGRESS_OF_CHALLENGE_GROUP".localized(),
                            it.progress
                        )
                    }
                    self.lbTimeRemain.text = String(
                        format: "FORMAT_TIME_REMAINING".localized(),
                        TimeUtils.getTimeRemain(challenge.endDate)
                    )
                    self.btnUpdateProgress.setTitle("UPDATE_PROGRESS".localized(), for: .normal)
                    //                    showAlertComplete(challenge)
                } else {
                    // Show view update progress
                    self.lbCurrentProgress.textColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
                    self.vUpdateChallenge.isHidden = false
                    self.vJoinChallenge.isHidden = true
                    self.completeImageView.isHidden = true
                    self.progressLowConstraint.priority = .defaultLow
                    self.progressHighConstraint.priority = .defaultHigh
                    
                    if challenge.challengeModeId == 1 {
                        self.lbCurrentProgress.text = String(
                            format: "FORMAT_CURRENT_PROGRESS_OF_CHALLENGE".localized(),
                            it.progress,
                            it.targetNumber
                        )
                    } else {
                        if it.progress != 0 {
                            self.lbCurrentProgress.text = String(
                                format: "FORMAT_CURRENT_PROGRESS_OF_CHALLENGE_GROUP".localized(),
                                it.progress
                            )
                        } else {
                            self.lbCurrentProgress.text = String(
                                format: "NOT_READ_BOOK_MESSEAGE".localized())
                        }
                    }
                    self.lbTimeRemain.text = String(
                        format: "FORMAT_TIME_REMAINING".localized(),
                        TimeUtils.getTimeRemain(challenge.endDate)
                    )
                }
            } else {
                // Show view join in challenge
                self.vUpdateChallenge.isHidden = true
                self.vJoinChallenge.isHidden = !Session.shared.isAuthenticated
            }
        }
            //expired
        else {
            if let it = challenge.challengeProgress {
                self.lbCurrentProgress.textColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
                self.completeImageView.isHidden = false
                self.progressLowConstraint.priority = .defaultHigh
                self.progressHighConstraint.priority = .defaultLow
                self.vUpdateChallenge.isHidden = false
                if challenge.challengeModeId == 1 {
                    self.lbCurrentProgress.text = String(
                        format: "FORMAT_CURRENT_PROGRESS_OF_CHALLENGE".localized(),
                        it.progress,
                        it.targetNumber
                    )
                } else {
                    self.lbCurrentProgress.text = String(
                        format: "FORMAT_CURRENT_PROGRESS_OF_CHALLENGE_GROUP".localized(),
                        it.progress
                    )
                }
                self.lbTimeRemain.text = "CHALLENGE_ENDED".localized()
                self.btnUpdateProgress.setTitle("SHARE_TITLE".localized(), for: .normal)
            }
        }
        
        if let it = challenge.challengeProgress {
            if it.targetNumber > 0 && it.progress >= it.targetNumber {
                // Show popup complete challenge
                showAlertComplete(challenge)
            }
        }
    }
    
    private func showAlertComplete(_ challenge: Challenge) {
        guard let popupVC = self.getViewControllerFromStorybroad(
            storybroadName: "AlertChallengeCompleteView",
            identifier: "AlertChallengeCompleteVC"
            ) as? AlertChallengeCompleteVC else { return }
        popupVC.challengeName = challenge.title
        popupVC.delegate = self
        popupVC.image = self.ivCover.image
        popupVC.challenge = self.challenge
        present(popupVC, animated: true, completion: nil)
    }
    
    private func bindViewModelMembers() {
        let useCase = Application.shared.networkUseCaseProvider
        viewModelMembers = ActiveMembersViewModel(useCase: useCase.makeLeaderBoardsUseCase())
        
        let input = ActiveMembersViewModel.Input(
            getData: self.getDataMembers,
            getLeaderBoards: .init(value: .init(challengeId: self.idChallenge, pageNum: 1)), getFriendLeaderBoards: .init(value: .init(challengeId: self.idChallenge, pageNum: 1))
        )
        let output = viewModelMembers.transform(input)
        
        output.leaderBoards.subscribe(onNext: { [weak self] result in
            guard let it = result.leaderBoards else {
                return
            }
            
            self?.activeMembers = Array(it.prefix(4)).filter { $0.progress > 0 }
            if !self!.activeMembers.isEmpty {
                self?.isHaveActiveMember = true
                self?.tableViewContent.reloadData()
            }
        })
            .disposed(by: disposeBag)
        
        output.friendLeaderBoards.subscribe(onNext: { [weak self] result in
            guard let it = result.leaderBoards else {
                return
            }
            
//            self?.section.append(.activeMember)
            self?.section.sort(by: { $0.rawValue < $1.rawValue })
            
            let indexPath = IndexPath(row: 0, section: 0)
            let cell = self?.tableViewContent.cellForRow(at: indexPath)
            if cell != nil {
                (cell as! ChallengeContentCell).setMembers(leaderBoards: it)
            }
        })
            .disposed(by: disposeBag)
        
        output.error
            .drive(rx.error)
            .disposed(by: disposeBag)
        
        self.getDataMembers.onNext(idChallenge)
    }
    
    private func onJoinEvent() {
        SwiftEventBus.onMainThread(self, name: JoinChallengeEvent.EVENT_NAME) { result in
            let target: JoinChallengeEvent? = result?.object as? JoinChallengeEvent
            if target != nil {
                self.joinChallenge.onNext(target!.targetNumber)
                SwiftEventBus.post(RefreshChallengesEvent.EVENT_NAME)
            }
        }
    }
    
    private func setOnUpdateCellHeightEvent() {
        SwiftEventBus.onMainThread(self, name: UpdateChallengeCellHeightEvent.EVENT_NAME) { result in
            let event: UpdateChallengeCellHeightEvent? = result?.object as? UpdateChallengeCellHeightEvent
            let isExpand = event?.isExpand ?? false
            print("setOnUpdateCellHeightEvent called result: \(isExpand)")
            if isExpand {
                let expHeight = ChallengeContentCell.getSize(lbWidth: self.view.frame.width, text: self.challenge?.description ?? "", lines: 0) - 50
                print("expHeight: \(expHeight), width: \(self.view.frame.width)")
                if expHeight > 0 { self.firstCellHeight += expHeight }
            } else {
                self.firstCellHeight = 320
            }
            self.tableViewContent.reloadData()
        }
    }
    
    private func onOpenMembersEvent() {
        SwiftEventBus.onMainThread(
            self,
            name: OpenChallengeMembersEvent.EVENT_NAME
        ) { result in
            print("Received event ")
            print("tapGesture event called")
            let eventData: OpenChallengeMembersEvent? = result?.object as? OpenChallengeMembersEvent
            //self.openMembersScreen(eventData?.isOpenFollowTab ?? false)
            self.performSegue(withIdentifier: "showActiveMembers",
                              sender: eventData?.isOpenFollowTab ?? false)
        }
    }
    
    private func openMembersScreen(_ isShowFollowTab: Bool) {
        self.performSegue(withIdentifier: "showActiveMembers", sender: isShowFollowTab)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showActiveMembers" {
            let vc = segue.destination as? ActiveMembersVC
            vc?.challenge = self.challenge
            vc?.isShowFollowTab = sender as! Bool
        } else if segue.identifier == "showUserVistor" {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        }
    }
    
    fileprivate func showUserVistor(_ profile: UserPublic) {
        if profile.profile.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
            let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
            vc.isShowButton.onNext(true)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.performSegue(withIdentifier: "showUserVistor", sender: profile)
        }
    }
    
    fileprivate func showInvitePopUp(_ success: Bool){
        if success == true {
            guard let popupVC = self.getViewControllerFromStorybroad(
                storybroadName: "ChallengeInviteView",
                identifier: ChallengeInviteVC.className
            ) as? ChallengeInviteVC else { return }
            popupVC.challenge = self.challenge
            present(popupVC, animated: true, completion: nil)
        } else {
           return
        }
    }
    
    fileprivate func showListBookTargetPopUp(_ success:Bool){
        if success == true {
            guard let popupVC = self.getViewControllerFromStorybroad(storybroadName: "ListBookTargetChallenge", identifier: PopUpListBookTargetVC.className) as? PopUpListBookTargetVC else {return}
            popupVC.challenge = self.challenge
            present(popupVC, animated: true, completion: nil)
        } else {
            let sb = UIStoryboard(name: "UpdateReadingTarget", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: UpdateReadingTargetVC.className) as! UpdateReadingTargetVC
            vc.challenge = self.challenge
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    fileprivate func showBookDetailWhenTapUpdateReadingCell(_ bookinfo:BookInfo){
        let storyboard = UIStoryboard(name: "BookDetail", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: BookDetailViewController.className) as! BookDetailViewController
        let book = BookInfo()
        book.editionId = bookinfo.editionId
        vc.bookInfo.onNext(book)
        self.navigationController?.pushViewController(vc, animated: true)
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
    
    @IBAction func unwindToChallengeDetail(_ sender: UIStoryboardSegue) {}
    
    @IBAction func backDidTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onShowMemu(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(
            title: "SHARE_TO_FACEBOOK".localized(),
            style: .default ,
            handler:{ (UIAlertAction
                ) in
                print("User click Approve button")
                self.shareFacebook()
        }))
        
        // Check time if Challenge is expired then cannot edit targetNumber
        if !TimeUtils.isExpiredNow(challenge?.endDate ?? "") {
            // Check to show edit only when targetModeId is setByUser
            if let mode = self.challenge?.targetModeId, mode == TargetModeId.setByUser.rawValue {
                //check only when login user is allowed to adjust target challenge
                if Session.shared.isAuthenticated {
                    alert.addAction(UIAlertAction(title: "CHANGE_CHALLENGE_TARGET".localized(), style: .default , handler:{ (UIAlertAction) in
                        self.openJoinChallengePopup()
                    }))
                    
                }
            }
        }
        
        alert.addAction(UIAlertAction(title: Gat.Text.CommonError.CANCEL_ERROR_TITLE.localized(), style: .cancel, handler:{ (UIAlertAction) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    private func shareFacebook() {
        let content = ShareLinkContent()
        let web: String = AppConfig.sharedConfig.get("web_url")
//        if let image = self.ivCover.image {
//            content.photos = [.init(image: image, userGenerated: true)]
//        } else if let challenge = challenge, let url = URL.init(string: AppConfig.sharedConfig.setUrlImage(id: challenge.imageCover, size: .o)) {
//            content.photos = [.init(imageURL: url, userGenerated: true)]
//        }
        content.hashtag = .init("#GATreadingchallenge")
        content.contentURL = URL(string: "\(web)challenges/\(self.idChallenge)")!
        let dialog = ShareDialog.init(fromViewController: self, content: content, delegate: self)
        dialog.show()
    }
    
    @objc func onBtnShareClicked() {
        
    }
    
    @IBAction func onJoinChallenge(_ sender: Any) {
        guard Session.shared.isAuthenticated else {
            HandleError.default.loginAlert()
            return
        }
        guard let targetNumber = challenge?.targetNumber else {return}
        if challenge?.targetModeId == 2{
            openJoinChallengePopup()
        } else {
            self.joinChallenge.onNext(targetNumber)
        }
    }
    
    private func openJoinChallengePopup() {
        guard let popupVC = self.getViewControllerFromStorybroad(
            storybroadName: "JoinChallengeView",
            identifier: "JoinChallengeVC"
            ) as? JoinChallengeVC else { return }
        popupVC.maxSlider = Float(self.challenge?.targetNumber ?? 0)
        popupVC.duration = TimeUtils.getTimeRemain(self.challenge?.endDate ?? "")
        popupVC.targetNumber = Float(self.challenge?.challengeProgress?.targetNumber ?? 0)
        // Set targetModeId
        var targetModeId = TargetModeId.fixValue
        if let mode = self.challenge?.targetModeId, mode == TargetModeId.setByUser.rawValue {
            targetModeId = TargetModeId.setByUser
        }
        popupVC.targetModeId = targetModeId
        present(popupVC, animated: true, completion: nil)
    }
    
    private func getReviews() {
        Observable.combineLatest(Status.reachable.asObservable(), self.page)
            .filter { $0.0 }
            .map { $0.1 }
            .flatMap {
                ReviewNetworkService.shared
                    .newReviews(page: $0)
                    .catchError { (error) -> Observable<[Review]> in
                        HandleError.default.showAlert(with: error)
                        return Observable<[Review]>.empty()
                    }
            }
            .subscribe(onNext: { [weak self] (reviews) in
                self?.reviews = reviews
            })
            .disposed(by: self.disposeBag)
    }

    
    @IBAction func onUpdateProgress(_ sender: Any) {
        guard let challenge = self.challenge else { return }
        if !TimeUtils.isExpiredNow(challenge.endDate) {
            if let it = self.challenge?.challengeProgress, it.targetNumber > 0 && it.progress >= it.targetNumber && challenge.challengeModeId == 2 {
                self.shareFacebook()
            } else if challenge.challengeModeId == 1 && challenge.targetTypeId == 3 {
                let sb = UIStoryboard(name: "UpdateReadingTarget", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: UpdateReadingTargetVC.className) as! UpdateReadingTargetVC
                vc.challenge = self.challenge
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                self.performSegue(withIdentifier: "showReadings", sender: nil)
            }
        } else {
            self.shareFacebook()
        }
    }
}

extension ChallengeDetailVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.section.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = self.section[indexPath.section]
        
        switch item {
        case .content:
            if self.challenge?.targetTypeId == 3 {
                return firstCellHeight + 150
            } else if self.challenge?.challengeModeId == 2 {
                return firstCellHeight - 30
            }
            else {
                return firstCellHeight
            }
        case .activeMember:
            return 170
        case .filter:
            return 60
        case .news:
            switch self.selectedItem {
            case .activity:
                return UITableView.automaticDimension
            case .article:
                return 300
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let item = self.section[section]
        
        switch item {
        case .content:
            return 1
        case .activeMember:
            return 1
        case .filter:
            return 1
        case .news:
            switch self.selectedItem {
            case .activity:
                return self.activities.count
            case .article:
                return self.listPost.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.section[indexPath.section]
        
        switch item {
        case .content:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeContentCell", for: indexPath) as! ChallengeContentCell
            cell.setOnClickListener()
            cell.setData(challenge: self.challenge)
            if self.challenge?.challengeProgress != nil {
                cell.isJoinedChallenge = true
            } else {
                cell.isJoinedChallenge = false
            }
            cell.receivedData(challenge: self.challenge)
            cell.showUser = self.showUserVistor
            cell.isTappedBtnInvite = self.showInvitePopUp
            cell.openBookTargetPopUpWhenTapCollection = self.showListBookTargetPopUp
            cell.setUpProgressView(challenge: self.challenge)
            
            cell.backgroundColor = .white
            let backgroundView = UIView()
            backgroundView.backgroundColor = .white//Colors.transparent
            cell.selectedBackgroundView = backgroundView
            
            return cell
        case .activeMember:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveMemberCollectionCell", for: indexPath) as! ActiveMemberCollectionCell
            cell.initActiveMembers()
            cell.setActiveMembers(leaderBoards: self.activeMembers)
            cell.showUser = self.showUserVistor
            
            cell.backgroundColor = .white
            let backgroundView = UIView()
            backgroundView.backgroundColor = .white//Colors.transparent
            cell.selectedBackgroundView = backgroundView
            
            return cell
        case .filter:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FilterTableViewCell", for: indexPath) as! FilterTableViewCell
            cell.itemSelectedHandler = { [weak self] (item) in
                self?.selectedItem = item
                self?.tableViewContent.reloadData()
            }
            
            cell.backgroundColor = .white
            let backgroundView = UIView()
            backgroundView.backgroundColor = .white//Colors.transparent
            cell.selectedBackgroundView = backgroundView
            
            return cell
        case .news:
            switch self.selectedItem {
            case .article:
                let cell = tableView.dequeueReusableCell(withIdentifier: SmallArticleTableViewCell.className, for: indexPath) as! SmallArticleTableViewCell
                cell.post.accept(self.listPost[indexPath.row])
                cell.likeEvent = { [weak self] reaction,count in
                    var art = self!.listPost[indexPath.row]
                    PostService.shared.reaction(postId: art.id, reactionId: reaction.rawValue, reactionCount: count)
                    .catchError({ (error) -> Observable<()> in
                        return .empty()
                    })
                    .subscribe(onNext: { (_) in
                        art.summary.reactCount += count
                        let increase = art.userReaction.reactCount + count
                        art.userReaction = .init(reactionId: reaction.rawValue, reactCount: increase)
                        self!.listPost[indexPath.row] = art
                        self!.tableViewContent.reloadData()
                    })
                    .disposed(by: self!.disposeBag)
                }
                
                cell.tapUser = { [weak self] success in
                    let art = self!.listPost[indexPath.row]
                    if success == true {
                        let cre = art.creator
                        let id = cre.profile.id
                        self?.openProfilePage(userId: id)
                    }
                }
                
                cell.tapBook = { [weak self] success in
                    let art = self!.listPost[indexPath.row]
                    if success == true {
                        let book = art.editionTags.first
                        if book != nil {
                            self?.showBookDetail(book!)
                        }
                    }
                }
                
                cell.showOption = { [weak self] post, success in
                    var art = self!.listPost[indexPath.row]
                    if success == true {
                        guard let popupVC = self!.getViewControllerFromStorybroad(storybroadName: "CreateArticle", identifier: PopupForMoreArticleVC.className) as? PopupForMoreArticleVC else {return}
                        popupVC.post.accept(post)
                        popupVC.isHideDelete.onNext(1)
                        self!.present(popupVC, animated: true, completion: nil)
                        popupVC.isTapSave = { [weak self] success in
                            if success == true {
                                self?.dismiss(animated: true, completion: nil)
                                art.saving = !post.saving
                                self!.listPost[indexPath.row] = art
                                self!.tableViewContent.reloadData()
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
                        self?.showPostDetail(self!.listPost[indexPath.row], style: style)
                    }
                }
                
                cell.backgroundColor = .white
                let backgroundView = UIView()
                backgroundView.backgroundColor = .white//Colors.transparent
                cell.selectedBackgroundView = backgroundView
                
                return cell
            case .activity:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeNewsCell", for: indexPath) as! ChallengeNewsCell
                cell.showUser = self.showUserVistor
                cell.setData(cActivity: self.activities[indexPath.row])
                cell.showBookDetail = self.showBookDetailWhenTapUpdateReadingCell
                
                cell.backgroundColor = .white
                let backgroundView = UIView()
                backgroundView.backgroundColor = .white//Colors.transparent
                cell.selectedBackgroundView = backgroundView
                
                return cell
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = -scrollView.contentOffset.y + coverViewMinHeight
        let height = max(y, coverViewMinHeight)
        self.coverHeightConstraint.constant = height
        //        print("height: \(height), offset: \(scrollView.contentOffset.y)")
        
        // Set logic show title when scroll to top
        // and hide title when user scroll down
        if height <= coverViewMinHeight {
            self.lbTitleBar.isHidden = false
            //self.vFade.isHidden = false
            self.vFade.backgroundColor = Colors.blueDark
        } else {
            self.lbTitleBar.isHidden = true
            //self.vFade.isHidden = true
            self.vFade.backgroundColor = Colors.grayTrans20
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard let param = self.getActivities.value else { return }
        guard Status.reachable.value else { return }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableViewContent.contentOffset.y >= (self.tableViewContent.contentSize.height - self.tableViewContent.frame.height) {
            if transition.y < -70 {
                self.getActivities.accept(.init(challengeId: param.challengeId, pageNum: param.pageNum + 1))
            }
        }
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
    
    fileprivate func showBookDetail(_ bookinfo:BookInfo){
        let storyboard = UIStoryboard(name: "BookDetail", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: BookDetailViewController.className) as! BookDetailViewController
        let book = BookInfo()
        book.editionId = bookinfo.editionId
        vc.bookInfo.onNext(book)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ChallengeDetailVC: SharingDelegate {
    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {}
    
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {}
    
    func sharerDidCancel(_ sharer: Sharing) {}
}

extension ChallengeDetailVC: AlertChallengeCompleteDelegate {
    func onJoinOtherChallenge() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
}

extension ChallengeDetailVC {
    enum Item: Int, CaseIterable {
        case article = 0
        case activity = 1
        
        var title: String {
            switch self {
            case .article: return "ARTICLES_TITLE".localized()
            case .activity: return "ACTIVITIES_TITLE".localized()
            }
        }
    }
    
    
}
