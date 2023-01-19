//
//  BookstopOrganizationShelveController.swift
//  gat
//
//  Created by Vũ Kiên on 14/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class BookstopOrganizationShelveController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var numberLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    let bookstop: BehaviorSubject<Bookstop> = .init(value: Bookstop())
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate let textSearch: BehaviorSubject<String?> = .init(value: nil)
    fileprivate var showStatus: SearchState = .new
    fileprivate let userSharingBooks: BehaviorSubject<[UserSharingBook]> = .init(value: [])
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupUI()
        self.getData()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable<(Bookstop,String?,Bool)>
            .combineLatest(self.bookstop, self.textSearch, Status.reachable.asObservable(), resultSelector: { ($0,$1,$2) })
            .filter { (_, _, status) in status }
            .map { (bookstop, text, _) in (bookstop, text) }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .totalSearchBook(of: $0, searchKey: $1, option: .all)
                    .map({ (total) -> String in
                        return String("\(total) \(Gat.Text.BookstopOrganization.BOOKS_TITLE.localized())")
                    })
                .catchErrorJustReturn("")
            }
            .bind(to: numberLabel.rx.text)
            .disposed(by: disposeBag)
            

        
        Observable<(Bookstop, String?, Int, Bool)>
            .combineLatest(self.bookstop, self.textSearch, self.page, Status.reachable.asObservable(), resultSelector: { ($0, $1, $2, $3) })
            .throttle(.microseconds(500), scheduler: MainScheduler.instance)
            .filter { (_, _, _, status) in status }
            .map { (bookstop, text, page, _) in (bookstop, text, page) }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .flatMapLatest {
                BookstopNetworkService
                    .shared
                    .listBook(of: $0, searchKey: $1, option: .all, page: $2)
                    .catchError { (error) -> Observable<[UserSharingBook]> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { [weak self] (userSharingBooks) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let status = self?.showStatus, let value = try? self?.userSharingBooks.value(), var list = value else {
                    return
                }
                switch status {
                case .new:
                    list = userSharingBooks
                    break
                case .more:
                    list.append(contentsOf: userSharingBooks)
                    break
                }
                self?.userSharingBooks.onNext(list)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        let textFieldInsideSearchBar = self.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = .black
        self.searchBar.placeholder = Gat.Text.BookstopOrganizaionShelve.SEARCH_PLACEHOLDER.localized()
        self.setupHeaderTitle(label: titleLabel)
        let share = self.bookstop.compactMap { $0.kind as? BookstopKindOrganization }.share()
        share.map { "\($0.totalEdition) \(Gat.Text.BookstopOrganization.BOOKS_TITLE.localized())" }.bind(to: self.numberLabel.rx.text).disposed(by: self.disposeBag)
        share.map { $0.totalEdition == 0 }.bind(to: self.numberLabel.rx.isHidden).disposed(by: self.disposeBag)
        self.setupCollectionView()
    }
    
    fileprivate func setupHeaderTitle(label: UILabel) {
        self.bookstop.compactMap { $0.profile }.map { String(format: "SHELVES_GATUP".localized(), $0.name) }.bind(to: label.rx.text).disposed(by: self.disposeBag)
    }

    
    fileprivate func setupCollectionView() {
        self.registerCell()
        self.collectionView.delegate = self
        var sizeCell = CGSize.zero
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 8.0
            layout.minimumInteritemSpacing = 8.0
            layout.sectionInset = .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
            layout.itemSize = .init(width: (UIScreen.main.bounds.width - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing * 2.0) / 3.0, height: 250.0)
            sizeCell = layout.itemSize
        }
        self.userSharingBooks.bind(to: self.collectionView.rx.items(cellIdentifier: Gat.Cell.IDENTIFIER_BOOK_COLLECTION, cellType: BookCollectionViewCell.self)) { [weak self] (index, userSharingBook, cell) in
            cell.delegate = self 
            cell.containerView.dropShadow(offset: .zero, radius: 5.0, opacity: 0.5, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
            cell.setupBook(info: userSharingBook.bookInfo)
            cell.sizeCell = sizeCell
        }.disposed(by: self.disposeBag)
    }
    
    fileprivate func registerCell() {
        let nib = UINib(nibName: Gat.View.BOOK_COLLECTION, bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: Gat.Cell.IDENTIFIER_BOOK_COLLECTION)
    }
    
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backButtonEvent()
        self.searchBarEvent()
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
    
    fileprivate func searchBarEvent() {
        self.searchBar
            .rx
            .textDidBeginEditing
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchBar.showsCancelButton = true
            })
            .disposed(by: self.disposeBag)
        
        self.searchBar
            .rx
            .searchButtonClicked
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchBar.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
        
        self.searchBar
            .rx
            .cancelButtonClicked
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchBar.resignFirstResponder()
                self?.searchBar.showsCancelButton = false
                self?.searchBar.text = ""
                self?.textSearch.onNext(self?.searchBar.text)
            })
            .disposed(by: self.disposeBag)
        
        self.searchBar.rx.text.asObservable().subscribe(self.textSearch).disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Gat.Segue.SHOW_BOOK_DETAIL_IDENTIFIER {
            let vc = segue.destination as? BookDetailViewController
            vc?.bookInfo.onNext(sender as! BookInfo)
        }
    }
}

extension BookstopOrganizationShelveController: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: (collectionView.frame.width - 48.0) / 3, height: 80.0)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 0.0
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 8.0
//    }
}

extension BookstopOrganizationShelveController: BookCollectionDelegate {
    func showBookDetail(identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    
}

//extension BookstopOrganizationShelveController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 100.0
//    }
//}

extension BookstopOrganizationShelveController {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.collectionView.contentOffset.y >= (self.collectionView.contentSize.height - self.collectionView.frame.height) {
            if transition.y < -100 {
                self.showStatus = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if Status.reachable.value {
            let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
            if scrollView.contentOffset.y == 0 {
                if transition.y > 150 {
                    self.showStatus = .new
                    self.page.onNext(1)
                }
            }
        }
    }
}

extension BookstopOrganizationShelveController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}









