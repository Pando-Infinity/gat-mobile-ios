//
//  RequestBorrowerBookstopViewController.swift
//  gat
//
//  Created by Vũ Kiên on 13/06/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class RequestBorrowerBookstopOrganizationViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var borrowBookTitleLabel: UILabel!
    @IBOutlet weak var fromTitleLabel: UILabel!
    @IBOutlet weak var bookContainerView: UIView!
    @IBOutlet weak var ownerContainerView: UIView!
    @IBOutlet weak var requestDetailView: RequestDetailBorrowerBookstopView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate var bookInfoView: BookRequestInfoView!
    fileprivate var ownerInfoView: InfoBookstopView!
    
    let bookRequest: BehaviorSubject<BookRequest> = .init(value: BookRequest())
    fileprivate let instance: BehaviorSubject<Instance?> = .init(value: nil)
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupBookInfoView()
        self.setupOwnerInfoView()
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
            .flatMap { (request) -> Observable<(Instance, Int, Int)> in
                return RequestNetworkService.shared.info(bookRequest: request)
                    .catchError { (error) -> Observable<(Instance, Int, Int)> in
                        HandleError.default.showAlert(with: error)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return .empty()
                }
        }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .do(onNext: { [weak self] (instance, sharingBook, reviewBook) in
                self?.bookRequest.onNext(instance.request!)
                self?.bookInfoView.setup(numberBookSharing: sharingBook, numberReviewBook: reviewBook)
                self?.requestDetailView.instance.onNext(instance)
                self?.instance.onNext(instance)
            })
            .map { $0.0.request! }
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
        self.titleLabel.text = Gat.Text.RequestBorrowerBookstop.TITLE.localized()
        self.borrowBookTitleLabel.text = Gat.Text.RequestBorrowerBookstop.YOU_BORROW_FROM_MESSAGE.localized()
        self.fromTitleLabel.text = Gat.Text.RequestBorrowerBookstop.FROM_MESSAGE.localized()
        self.bookRequest
            .subscribe(onNext: { [weak self] (bookRequest) in
                self?.bookInfoView.setup(book: bookRequest.book!)
                let bookstop = Bookstop()
                bookstop.id = bookRequest.owner!.id
                bookstop.profile = bookRequest.owner
                self?.ownerInfoView.bookstop.onNext(bookstop)
                self?.requestDetailView.bookRequest.onNext(bookRequest)
            })
            .disposed(by: self.disposeBag)
        self.instance.filter { $0 != nil }.map { $0! }
            .map { $0.owner as? Bookstop }.filter { $0 != nil }.map { $0! }
            .subscribe(onNext: { [weak self] (bookstop) in
                self?.ownerInfoView.bookstop.onNext(bookstop)
            })
            .disposed(by: self.disposeBag)
        self.requestDetailView.delegate = self
    }
    
    fileprivate func setupBookInfoView() {
        self.view.layoutIfNeeded()
        self.bookInfoView = Bundle.main.loadNibNamed("InfoBookRequestView", owner: self, options: nil)?.first as? BookRequestInfoView
        self.bookInfoView.frame = self.bookContainerView.bounds
        self.bookInfoView.delegate = self
        self.bookContainerView.addSubview(self.bookInfoView)
    }

    fileprivate func setupOwnerInfoView() {
        self.view.layoutIfNeeded()
        self.ownerInfoView = Bundle.main.loadNibNamed("InfoBookstopOrganizationView", owner: self, options: nil)?.first as? InfoBookstopView
        self.ownerInfoView.frame = self.ownerContainerView.bounds
        self.ownerInfoView.delegate = self
        self.ownerContainerView.addSubview(self.ownerInfoView)
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
        if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        } else if segue.identifier == "showBookstopOrganization" {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        }
    }

}

extension RequestBorrowerBookstopOrganizationViewController: BookRequestInfoDelegate {
    func showBookInfo(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
    
}

extension RequestBorrowerBookstopOrganizationViewController: InfoBookstopDelegate {
    func showBookstop(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    
}

extension RequestBorrowerBookstopOrganizationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension RequestBorrowerBookstopOrganizationViewController: RequestDetailBorrowerBookstopDelegate {
    func update() {
        self.getData()
    }
    
    
}
