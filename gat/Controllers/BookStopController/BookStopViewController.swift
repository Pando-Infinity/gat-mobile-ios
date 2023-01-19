//
//  BookStopController.swift
//  gat
//
//  Created by Vũ Kiên on 28/09/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class BookStopViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var backgroundHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookstopDetail: BookstopDetailView!
    @IBOutlet weak var profileTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookstopTabContainerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var aboutTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var aboutBottomConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    let bookstop: BehaviorSubject<Bookstop> = .init(value: Bookstop())
    var bookstopTabView: BookstopTabItemView!
    var controllers: [UIViewController] = []
    var previousVC: UIViewController?
    fileprivate var images: [BookstopImage] = []
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.getData()
        self.setupUI()
        self.event()
        self.performSegue(withIdentifier: "showBookCase", sender: nil)
    }
    
    //MARK: - Data
    fileprivate func getData() {
        Observable<(Bookstop, Bool)>
            .combineLatest(self.bookstop.elementAt(0), Status.reachable.asObservable(), resultSelector: { ($0, $1) })
            .filter { (_, status) in status }
            .map { (bookstop, _) in bookstop }
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .info(bookstop: $0)
                    .catchError { (error) -> Observable<Bookstop> in
                        return Observable.empty()
                    }
            }
            .subscribe(self.bookstop)
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.view.layoutIfNeeded()
        self.setupBookStopDetail()
        self.setupBookstopTabItem()
    }
    
    fileprivate func setupBookStopDetail() {
        self.bookstopDetail.controller = self
        self.bookstop
            .subscribe(onNext: { [weak self] (bookstop) in
                self?.bookstopDetail.setupUI(bookstop: bookstop)
                self?.setupAbout(bookstop.profile!.about)
                if bookstop.profile!.coverImageId.isEmpty {
                    self?.view.layoutIfNeeded()
                    self?.backgroundView.applyGradient(colors: GRADIENT_BACKGROUND_COLORS)
                } else {
                    self?.backgroundImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: bookstop.profile!.coverImageId, size: .q))!)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupAbout(_ about: String) {
        self.aboutLabel.text = about
        self.aboutTopConstraint.constant = about.isEmpty ? 0.0 : 8.0
        self.aboutBottomConstraint.constant = about.isEmpty ? 0.0 : 8.0
    }
    
    fileprivate func setupBookstopTabItem() {
        self.bookstopTabView = Bundle.main.loadNibNamed("BookstopTabItemView", owner: self, options: nil)?.first as? BookstopTabItemView
        self.bookstopTabView.frame = self.bookstopTabContainerView.bounds
        self.bookstopTabView.bookstopController = self
        self.bookstopTabContainerView.addSubview(self.bookstopTabView)
    }
    
    func changeFrameProfileView(height: CGFloat) {
        self.backgroundHeightConstraint.constant = height - self.backgroundHeightConstraint.multiplier * self.view.frame.height
        let progress = (height - self.view.frame.height * self.headerHeightConstraint.multiplier) / (self.backgroundHeightConstraint.multiplier * self.view.frame.height - self.view.frame.height * self.headerHeightConstraint.multiplier)
        self.profileTopConstraint.constant = -(1.0 - progress) * self.headerHeightConstraint.multiplier * self.view.frame.height
        self.bookstopDetail.changeFrame(progress: 1.0 - progress)
        self.view.layoutIfNeeded()
    }
    
    fileprivate func showAlert(title: String = Gat.Text.CommonError.ERROR_ALERT_TITLE.localized(), message: String, actions: [ActionButton]) {
        AlertCustomViewController.showAlert(title: title, message: message, actions: actions, in: self)
    }
    
    //MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == /*Gat.Segue.SHOW_BOOK_CASE_IDENTIFIER*/ "showBookCase" {
            let vc = segue.destination as? BookCaseViewController
            vc?.bookstopController = self
        
        } else if segue.identifier == /*Gat.Segue.SHOW_BOOK_SPACE_IDENTIFIER*/ "showBookSpace" {
            let vc = segue.destination as? BookSpaceViewController
            vc?.bookstopController = self
        } else if segue.identifier == /*Gat.Segue.SHOW_IMAGE_BOOK_STOP_IDENTIFIER*/ "showImageBookstop" {
            let vc = segue.destination as? ImageInfoBookstopViewController
            vc?.selected.onNext(sender as! BookstopImage)
            self.bookstop
                .subscribe(onNext: { (bookstop) in
                    vc?.bookstop.onNext(bookstop)
                })
                .disposed(by: self.disposeBag)
        } else if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        }
    }
}

extension BookStopViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
