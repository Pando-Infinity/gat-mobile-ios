//
//  RequestOwnerViewController.swift
//  gat
//
//  Created by Vũ Kiên on 07/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class RequestOwnerViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var borrowerInfoContainerView: UIView!
    @IBOutlet weak var requestTitleLabel: UILabel!
    @IBOutlet weak var bookInfoContainerView: UIView!
    @IBOutlet weak var timelineContainerView: UIView!
    @IBOutlet weak var timelineHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var requestDetailView: RequestDetailOwnerView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate var bookInfoView: BookRequestInfoView!
    fileprivate var borrowerInfoView: UserRequestInfoView!
    fileprivate var timelineView: TimelineRequestView!
    
    fileprivate var currentTimelineFrame: CGRect!
    
    let bookRequest: BehaviorSubject<BookRequest> = .init(value: BookRequest())
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.getData()
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
            .do(onNext: { [weak self] (bookRequest, sharingBook, reviewBook, totalBookUser, totalReviewUser) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.bookRequest.onNext(bookRequest)
                self?.bookInfoView.setup(numberBookSharing: sharingBook, numberReviewBook: reviewBook)
                self?.borrowerInfoView.setup(numberBook: totalBookUser, numberReview: totalReviewUser)
            })
            .map { (bookRequest, _, _, _, _) in bookRequest }
            .flatMapLatest({ (bookRequest) -> Observable<BookRequest> in
                return Observable<BookRequest>
                    .combineLatest(
                        Observable<BookRequest>.just(bookRequest),
                        Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                        resultSelector: { (bookRequest, userPrivate) -> BookRequest in
                            bookRequest.owner = userPrivate.profile
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
        self.currentTimelineFrame = self.timelineContainerView.frame
        self.titleLabel.text = Gat.Text.OwnerRequestDetail.OWNER_REQUEST_DETAIL.localized()
        self.requestTitleLabel.text = Gat.Text.OwnerRequestDetail.SEND_REQUEST_BORROW_BOOK_TITLE.localized()
        self.setupBookInfoView()
        self.setupBorrowerInfoView()
        self.setupTimelineView()
        self.requestDetailView.delegate = self
        self.bookRequest
            .subscribe(onNext: { [weak self] (bookRequest) in
                self?.view.layoutIfNeeded()
                self?.bookInfoView.setup(book: bookRequest.book!)
                self?.bookInfoView.frame = self?.bookInfoContainerView.bounds ?? .zero
                self?.borrowerInfoView.setup(profile: bookRequest.borrower!)
                self?.timelineView.setupExpectation(time: bookRequest.borrowExpectation)
                self?.requestDetailView.bookRequest.onNext(bookRequest)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupBookInfoView() {
        self.view.layoutIfNeeded()
        self.bookInfoView = Bundle.main.loadNibNamed("InfoBookRequestView", owner: self, options: nil)?.first as? BookRequestInfoView
        self.bookInfoView.frame = self.bookInfoView.bounds
        self.bookInfoView.delegate = self
        self.bookInfoContainerView.addSubview(self.bookInfoView)
    }
    
    fileprivate func setupBorrowerInfoView() {
        self.view.layoutIfNeeded()
        self.borrowerInfoView = Bundle.main.loadNibNamed("InfoUserRequestView", owner: self, options: nil)?.first as? UserRequestInfoView
        self.borrowerInfoView.frame = self.borrowerInfoContainerView.bounds
        self.borrowerInfoView.delegate = self
        self.borrowerInfoContainerView.addSubview(self.borrowerInfoView)
    }
    
    fileprivate func setupTimelineView() {
        self.view.layoutIfNeeded()
        self.timelineView = Bundle.main.loadNibNamed("TimelineRequestView", owner: self, options: nil)?.first as? TimelineRequestView
        self.timelineView.frame = self.timelineContainerView.bounds
        self.timelineContainerView.addSubview(self.timelineView)
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
                self?.timelineView.frame = self?.timelineContainerView.bounds ?? .zero
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

extension RequestOwnerViewController: RequestDetailDelegate {
    func loading(_ isLoading: Bool) {
        self.view.isUserInteractionEnabled = !isLoading
    }
    
    func update() {
        self.getData()
    }
}

extension RequestOwnerViewController: UserRequestInfoDelegate {
    
    func showMessage(groupId: String) {
        guard let request = try? self.bookRequest.value() else { return }
        let storyboard = UIStoryboard(name: Gat.Storyboard.Message, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: Gat.View.MessageViewController) as! MessageViewController
        var group = Repository<GroupMessage, GroupMessageObject>.shared.get(predicateFormat: "groupId = %@", args: [groupId])
        if group == nil {
            group = GroupMessage()
            group?.groupId = groupId
            group?.users.append(request.borrower!)
        }
        vc.group.onNext(group!)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showVistorUser(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension RequestOwnerViewController: BookRequestInfoDelegate {
    func showBookInfo(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
    
}

extension RequestOwnerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
