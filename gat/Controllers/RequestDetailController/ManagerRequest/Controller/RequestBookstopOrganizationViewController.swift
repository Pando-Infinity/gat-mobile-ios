//
//  RequestBookstopOrganizationViewController.swift
//  gat
//
//  Created by Vũ Kiên on 16/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class RequestBookstopOrganizationViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoContainerView: UIView!
    @IBOutlet weak var timeContainerView: UIView!
    @IBOutlet weak var bookContainerView: UIView!
    @IBOutlet weak var bookInfoLabel: UILabel!
    @IBOutlet weak var heightTimeConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate var infoBookstopView: InfoBookstopView!
    fileprivate var timeRequestView: TimeRequestBooktopView!
    fileprivate var bookInfoView: BookRequestInfoView!
    fileprivate var joinView: JoinBookstopView!
    fileprivate let borrowerInfo = Bundle.main.loadNibNamed("InfoUserRequestView", owner: self, options: nil)?.first as! UserRequestInfoView
    
    let instance = BehaviorSubject<Instance>(value: Instance())
    fileprivate let total: BehaviorSubject<(Int, Int)> = .init(value: (0, 0))
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable<(Instance, Bool)>
            .combineLatest(
                Observable<Instance>.from(optional: try? self.instance.value()),
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1) }
            )
            .filter { $0.id != 0 && $1 }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .map { (instance, _ ) in instance }
            .flatMapLatest {
                InstanceNetworkService
                    .shared
                    .info(instanceId: $0.id)
                    .catchError({ (error) -> Observable<(Instance, Int, Int, Int, Int)> in
                        HandleError.default.showAlert(with: error)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return Observable.empty()
                    })
            }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .subscribe(onNext: { [weak self] (instance, totalBook, reviewCount, totalBookBorrower, totalReviewBorrower) in
                self?.instance.onNext(instance)
                self?.total.onNext((totalBook, reviewCount))
                self?.borrowerInfo.setup(numberBook: totalBookBorrower, numberReview: totalReviewBorrower)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.bookInfoLabel.text = Gat.Text.RequestBookstop.BOOK_INFO.localized()
        self.instance
            .filter { $0.id != 0 }
            .filter { $0.owner?.profile?.userTypeFlag == .organization }
            .flatMapLatest({ (instance) -> Observable<Instance> in
                return Observable<Instance>
                    .combineLatest(
                        Observable<Instance>.just(instance),
                        Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first },
                        resultSelector: { (instance, userPrivate) -> Instance in
                            if instance.borrower?.id == userPrivate?.id {
                                instance.borrower = userPrivate?.profile
                            }
                            return instance
                    })
            })
            .subscribe(onNext: { [weak self] (instance) in
                guard let bookstop = instance.owner as? Bookstop else {
                    return
                }
                self?.titleLabel.text = bookstop.profile?.name
                self?.setupInfoBookstop(bookstop)
                if instance.bookstopMember {
                    if instance.sharingStatus == .selfManagerAndAvailable {
                        self?.setupTimeRequest(instance: instance)
                    } else if let borrower = instance.borrower {
                        if borrower.id == Repository<UserPrivate, UserPrivateObject>.shared.get()?.id {
                            self?.setupTimeRequest(instance: instance)
                        } else {
                            self?.setupBorrower(borrower)

                        }
                    }
                    
                } else {
                    self?.setupJoinView(bookstop: bookstop)
                }
                self?.setupBookInfoView(info: instance.book)
            })
            .disposed(by: self.disposeBag)
        
        self.total
            .subscribe(onNext: { [weak self] (totalBook, reviewCount) in
                if self?.bookInfoView != nil {
                    self?.bookInfoView.numberReviewBookLabel.text = "\(reviewCount)"
                    self?.bookInfoView.numberSharingBookLabel.text = "\(totalBook)"
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupInfoBookstop(_ bookstop: Bookstop) {
        if self.infoBookstopView == nil {
            self.view.layoutIfNeeded()
            self.infoBookstopView = Bundle.main.loadNibNamed("InfoBookstopOrganizationView", owner: self, options: nil)?.first as? InfoBookstopView
            self.infoBookstopView.frame = self.infoContainerView.bounds
            self.infoBookstopView.delegate = self
            self.infoContainerView.addSubview(self.infoBookstopView)
        }
        
        self.infoBookstopView.bookstop.onNext(bookstop)
    }
    
    fileprivate func setupTimeRequest(instance: Instance) {
        self.heightTimeConstraint.constant = 80.0
        self.view.layoutIfNeeded()
        if self.timeRequestView == nil {
            self.view.layoutIfNeeded()
            self.timeRequestView = Bundle.main.loadNibNamed("TimeRequestBookstopView", owner: self, options: nil)?.first as? TimeRequestBooktopView
            self.timeRequestView.frame = self.timeContainerView.bounds
            self.timeContainerView.addSubview(self.timeRequestView)
            self.timeRequestView.delegate = self
        }
        self.timeRequestView.instance.onNext(instance)
    }
    
    fileprivate func setupBorrower(_ borrower: Profile) {
        self.heightTimeConstraint.constant = 140.0
        self.view.layoutIfNeeded()
        let label = UILabel()
        label.text = Gat.Text.RequestBookstop.BORROWER_INFO.localized()
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = .black
        label.frame.origin = .init(x: 8.0, y: 0.0)
        label.sizeToFit()
        self.timeContainerView.addSubview(label)
        
        self.borrowerInfo.setup(profile: borrower)
        let width = self.timeContainerView.frame.width * 14.0 / 15.0
        self.borrowerInfo.frame = .init(origin: .init(x: (self.timeContainerView.frame.width - width) / 2.0, y: label.frame.height + 8.0), size: .init(width: width, height: self.timeContainerView.frame.height - 8.0 - label.frame.height))
        self.timeContainerView.addSubview(self.borrowerInfo)
        self.borrowerInfo.delegate = self
        
        
        
    }
    
    fileprivate func setupJoinView(bookstop: Bookstop) {
        let width = self.timeContainerView.frame.width * 14.0 / 15.0
        self.view.layoutIfNeeded()
        let size = JoinBookstopView.size(bookstop: bookstop, in: .init(width: width, height: self.timeContainerView.frame.height))
        self.heightTimeConstraint.constant = size.height
        self.view.layoutIfNeeded()
        if self.joinView == nil {
            self.view.layoutIfNeeded()
            self.joinView = Bundle.main.loadNibNamed("JoinBookstopOrganizationView", owner: self, options: nil)?.first as? JoinBookstopView
            self.joinView.frame = .init(x: (self.timeContainerView.frame.width - width) / 2.0, y: 0.0, width: width, height: self.timeContainerView.frame.height)
            self.timeContainerView.addSubview(self.joinView)
            self.joinView.delegate = self
        }
        self.joinView.bookstop.onNext(bookstop)
    }
    
    fileprivate func setupBookInfoView(info: BookInfo) {
        if self.bookInfoView == nil {
            self.view.layoutIfNeeded()
            self.bookInfoView = Bundle.main.loadNibNamed("InfoBookRequestView", owner: self, options: nil)?.first as? BookRequestInfoView
            let width = self.bookContainerView.frame.width * 14.0 / 15.0
            self.bookInfoView.frame = .init(x: (self.bookContainerView.frame.width - width) / 2.0, y: self.bookInfoLabel.frame.origin.y + self.bookInfoLabel.frame.height + 8.0, width: width, height: self.bookContainerView.frame.height * 0.25)
            self.bookInfoView.delegate = self
            self.bookContainerView.addSubview(self.bookInfoView)
        }
        
        self.bookInfoView.setup(book: info)
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
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
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
        } else if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as! UserVistorViewController
            let userPublic = UserPublic()
            userPublic.profile = sender as! Profile
            vc.userPublic.onNext(userPublic)
        }
    }

}

extension RequestBookstopOrganizationViewController: BookRequestInfoDelegate {
    func showBookInfo(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    
}

extension RequestBookstopOrganizationViewController: InfoBookstopDelegate {
    func showBookstop(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    
}

extension RequestBookstopOrganizationViewController: JoinBookstopDelegate {
    func showJoin(viewController: UIViewController) {
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func updateInstance() {
        do {
            let value = try self.instance.value()
            value.bookstopMember = true
            self.instance.onNext(value)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
}

extension RequestBookstopOrganizationViewController: TimeRequestBookstopDelegate {
    func updateInstance(bookRequest: BookRequest, sharingStatus: SharingStatus) {
        do {
            let value = try self.instance.value()
            value.request = bookRequest
            value.sharingStatus = sharingStatus
            value.borrower = bookRequest.borrower
            self.instance.onNext(value)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
}

extension RequestBookstopOrganizationViewController: UserRequestInfoDelegate {
    func showMessage(groupId: String) {
        guard let instance = try? self.instance.value() else { return }
        let storyboard = UIStoryboard(name: Gat.Storyboard.Message, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: Gat.View.MessageViewController) as! MessageViewController
        var group = Repository<GroupMessage, GroupMessageObject>.shared.get(predicateFormat: "groupId = %@", args: [groupId])
        if group == nil {
            group = GroupMessage()
            group?.groupId = groupId
            group?.users.append(instance.borrower!)
        }
        vc.group.onNext(group!)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showVistorUser(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension RequestBookstopOrganizationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
