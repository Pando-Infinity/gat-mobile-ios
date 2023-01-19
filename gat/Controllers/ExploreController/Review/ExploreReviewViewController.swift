//
//  ExploreReviewViewController.swift
//  gat
//
//  Created by Vũ Kiên on 06/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//
import UIKit
import RxSwift

class ExploreReviewViewController: UIViewController {
    
    class var segueIdentifier: String { return "showExploreReview" }

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var showStatus = SearchState.new
    fileprivate var reviews = [Review]()
    
    // MARK: - LifeTime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getReviews()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getReviews() {
        Observable<(Int, Bool)>
            .combineLatest(self.page, Status.reachable.asObservable(), resultSelector: { ($0, $1) })
            .filter { (_, status) in  status }
            .map { (page, _) in page }
            .flatMapLatest {
                ReviewNetworkService
                    .shared
                    .newReviews(page: $0)
                    .catchError { (error) -> Observable<[Review]> in
                        HandleError.default.showAlert(with: error)
                        return Observable<[Review]>.empty()
                    }
            }
            .filter { !$0.isEmpty }
            .subscribe(onNext: { [weak self] (reviews) in
                guard let status = self?.showStatus else {
                    return
                }
                switch status {
                case .new:
                    self?.reviews = reviews
                    break
                case .more:
                    self?.reviews.append(contentsOf: reviews)
                    break
                }
                self?.tableView.reloadData()
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setUpTitleLabel(){
        let attachment = NSTextAttachment()
        attachment.image = UIImage.init(named: "reviews")
        // Set bound to reposition
        let imageOffsetY: CGFloat = -4.0
        attachment.bounds = CGRect(x: 0, y: imageOffsetY, width: attachment.image!.size.width, height: attachment.image!.size.height)
        let attachmentString = NSAttributedString(attachment: attachment)
        let myString = NSMutableAttributedString(string: "")
        myString.append(attachmentString)
        let titleChallenge = NSMutableAttributedString(string: " \(Gat.Text.ReviewExplore.TITLE.localized())")
        myString.append(titleChallenge)
        self.titleLabel.textAlignment = .center
        self.titleLabel.attributedText = myString
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        setUpTitleLabel()
//        self.titleLabel.text = Gat.Text.ReviewExplore.TITLE.localized()
        self.registerNewReviewCell()
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    fileprivate func registerNewReviewCell() {
        let nib = UINib(nibName: "ReviewTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "newReviewCell")
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        LanguageHelper.changeEvent.subscribe(onNext: self.tableView.reloadData).disposed(by: self.disposeBag)
        self.backEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_USERPAGE_IDENTIFIER {
            let vc = segue.destination as? UserVistorViewController
            vc?.userPublic.onNext(sender as! UserPublic)
        } else if segue.identifier == "showProfile" {
            let vc = segue.destination as? ProfileViewController
            vc?.isShowButton.onNext(true)
        }
    }

}

extension ExploreReviewViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return self.reviews.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "topReviewerCell", for: indexPath) as! ReviewerTableViewCell
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "newReviewCell", for: indexPath) as! NewReviewTableViewCell
            cell.delegate = self
            cell.setup(review: self.reviews[indexPath.row])
            return cell
        }
    }
}

extension ExploreReviewViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 150.0
        } else {
            return 350.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = Bundle.main.loadNibNamed("HeaderSearch", owner: self, options: nil)?.first as? HeaderSearch
        if section == 0 {
            view?.titleLabel.text = Gat.Text.ReviewExplore.TOP_REVIEWERS_TITLE.localized()
        } else {
            if self.reviews.isEmpty {
                return UIView()
            }
            view?.titleLabel.text = Gat.Text.ReviewExplore.NEW_REVIEW_TITLE.localized()
        }
        view?.titleLabel.textColor = .black
        view?.titleLabel.font = .systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
        view?.backgroundColor = .white
        view?.showView.isHidden = true
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35.0 * tableView.frame.height / 667.0
    }
}

extension ExploreReviewViewController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.tableView.contentOffset.y >= self.tableView.contentSize.height - self.tableView.frame.height {
            if transition.y < -70 {
                self.showStatus = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if scrollView.contentOffset.y == 0 {
            if transition.y > 100 {
                self.showStatus = .more
                self.page.onNext(1)
            }
        }
    }
}

extension ExploreReviewViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension ExploreReviewViewController: NewReviewDelegate {
    func showReview(viewcontroller: UIViewController) {
        self.navigationController?.pushViewController(viewcontroller, animated: true)
    }
    
    func update(review: Review) {
        self.reviews
            .filter { $0.reviewId == review.reviewId }
            .first?
            .saving = review.saving
    }
}

extension ExploreReviewViewController: ReviewerCellDelegate {
    func showView(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    
}
