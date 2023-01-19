//
//  RequestBorrowerViewController.swift
//  gat
//
//  Created by Vũ Kiên on 04/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class RequestBorrowerViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var requestMessageLabel: UILabel!
    @IBOutlet weak var bookInfoContainerView: UIView!
    @IBOutlet weak var timeLineContainerView: UIView!
    @IBOutlet weak var ownerContainerView: UIView!
    @IBOutlet weak var requestDetailView: RequestDetailBorrowerView!
    @IBOutlet weak var timelineHeightConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate var bookInfoView: BookRequestInfoView!
    fileprivate var ownerInfoView: UserRequestInfoView!
    fileprivate var timelineView: TimelineRequestView!
    
    fileprivate var currentTimelineFrame: CGRect!
    
    let bookRequest: BehaviorSubject<BookRequest> = .init(value: BookRequest())
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - LifeTime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable<(BookRequest, Bool)>
            .combineLatest(
                Observable<BookRequest>.from(optional: try? self.bookRequest.value()),
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1) }
            )
            .filter { (_, status) in status }
            .map { (bookRequest, _) in bookRequest }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest({ (bookRequest) -> Observable<(BookRequest, Int, Int, Int, Int)> in
                return RequestNetworkService
                    .shared
                    .info(bookRequest: bookRequest)
                    .catchError({ (error) -> Observable<(BookRequest, Int, Int, Int, Int)> in
                        HandleError.default.showAlert(with: error)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return Observable.empty()
                    })
            })
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .do(onNext: { [weak self] (bookRequest, sharingBook, reviewBook, totalBookUser, totalReviewUser) in
                self?.bookRequest.onNext(bookRequest)
                self?.bookInfoView.setup(numberBookSharing: sharingBook, numberReviewBook: reviewBook)
                self?.ownerInfoView.setup(numberBook: totalBookUser, numberReview: totalReviewUser)
            })
            .map { (bookRequest, _, _, _, _) in bookRequest }
            .flatMapLatest({ (bookRequest) -> Observable<BookRequest> in
                return Observable<BookRequest>
                    .combineLatest(
                        Observable<BookRequest>.just(bookRequest),
                        Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                        resultSelector: { (bookRequest, userPrivate) -> BookRequest in
                            bookRequest.borrower = userPrivate.profile
                            return bookRequest
                    }
                )
            })
            .flatMapLatest { Repository<BookRequest, BookRequestObject>.shared.save(object: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.view.layoutIfNeeded()
        self.currentTimelineFrame = self.timeLineContainerView.frame
        self.titleLabel.text = Gat.Text.BorrowerRequestDetail.BORROWER_REQUEST_DETAIL.localized()
        self.requestMessageLabel.text = Gat.Text.BorrowerRequestDetail.YOU_SEND_REQUEST_BORROW_TITLE.localized()
        self.setupBookInfo()
        self.setupOwnerInfo()
        self.setupTimeLine()
        self.requestDetailView.delegate = self
        self.bookRequest
            .subscribe(onNext: { [weak self] (bookRequest) in
                self?.view.layoutIfNeeded()
                self?.bookInfoView.setup(book: bookRequest.book!)
                self?.ownerInfoView.setup(profile: bookRequest.owner!)
                self?.timelineView.setupExpectation(time: bookRequest.borrowExpectation)
                self?.requestDetailView.bookRequest.onNext(bookRequest)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupBookInfo() {
        self.view.layoutIfNeeded()
        self.bookInfoView = Bundle.main.loadNibNamed("InfoBookRequestView", owner: self, options: nil)?.first as? BookRequestInfoView
        self.bookInfoView.frame = self.bookInfoContainerView.bounds
        self.bookInfoView.delegate = self
        self.bookInfoContainerView.addSubview(self.bookInfoView)
    }
    
    fileprivate func setupOwnerInfo() {
        self.view.layoutIfNeeded()
        self.ownerInfoView = Bundle.main.loadNibNamed("InfoUserRequestView", owner: self, options: nil)?.first as? UserRequestInfoView
        self.ownerInfoView.frame = self.ownerContainerView.bounds
        self.ownerInfoView.delegate = self
        self.ownerContainerView.addSubview(self.ownerInfoView)
    }
    
    fileprivate func setupTimeLine() {
        self.view.layoutIfNeeded()
        self.timelineView = Bundle.main.loadNibNamed("TimelineRequestView", owner: self, options: nil)?.first as? TimelineRequestView
        self.timelineView.frame = self.timeLineContainerView.bounds
        self.timeLineContainerView.addSubview(self.timelineView)
        self.bookRequest
            .map { (bookRequest) -> [(String, Date?)] in
                return [
                    (Gat.Text.BorrowerRequestDetail.DATE_SEND_REQUEST_TITLE.localized(), bookRequest.requestTime),
                    (Gat.Text.BorrowerRequestDetail.DATE_START_BORROW_TITLE.localized(), bookRequest.borrowTime),
                    (Gat.Text.BorrowerRequestDetail.DATE_RETURN_BOOK_TITLE.localized(), bookRequest.completeTime),
                    (Gat.Text.BorrowerRequestDetail.DATE_REJECT_REQUEST_TITLE.localized(), bookRequest.rejectTime),
                    (Gat.Text.BorrowerRequestDetail.DATE_CANCEL_REQUEST_TITLE.localized(), bookRequest.cancelTime)
                ]
            }
            .map { (timeline) -> [(String, Date)] in
                return timeline.filter { $0.1 != nil }.map { ($0.0, $0.1!) }
            }
            .do(onNext: { [weak self] (timeline) in
                guard let frame = self?.currentTimelineFrame, let constant = self?.timelineView.titleHeightConstraint.constant else {
                    return
                }
                self?.timelineHeightConstraint.constant = constant * CGFloat(timeline.count + 1) - frame.height
                self?.view.needsUpdateConstraints()
                self?.timelineView.frame = self?.timeLineContainerView.bounds ?? .zero
            })
            .subscribe(self.timelineView.timeline)
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .tap
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            let userPublic = UserPublic()
            userPublic.profile = sender as! Profile
            vc?.userPublic.onNext(userPublic)
        } else if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        }
    }

}

extension RequestBorrowerViewController: UserRequestInfoDelegate {
    func showMessage(groupId: String) {
        guard let request = try? self.bookRequest.value() else { return }
        let storyboard = UIStoryboard(name: Gat.Storyboard.Message, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: Gat.View.MessageViewController) as! MessageViewController
        var group = Repository<GroupMessage, GroupMessageObject>.shared.get(predicateFormat: "groupId = %@", args: [groupId])
        if group == nil {
            group = GroupMessage()
            group?.groupId = groupId
            group?.users.append(request.owner!)
        }
        vc.group.onNext(group!)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showVistorUser(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension RequestBorrowerViewController: BookRequestInfoDelegate {
    func showBookInfo(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
    
}

extension RequestBorrowerViewController: RequestDetailDelegate {
    func loading(_ isLoading: Bool) {
        self.view.isUserInteractionEnabled = !isLoading
    }
    
    func update() {
        self.getData()
    }
}

extension RequestBorrowerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
