//
//  BookSuggestionTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 10/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import CoreLocation
import NVActivityIndicatorView

class BookSuggestionTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var controller: SuggestViewController?
    
    fileprivate var loadingView: NVActivityIndicatorView?
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let page = BehaviorSubject<Int>(value: 1)
    fileprivate let range = BehaviorSubject<Int>(value: 1)
    fileprivate let bookSuggestions = BehaviorSubject<[BookSharing]>(value: [])
    fileprivate var showStatus: SearchState = .new
    fileprivate let activeFindSuggest = BehaviorSubject<Bool>(value: true)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupUI()
        self.getData()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        self.getDataLocal()
        self.getDataServer()
    }
    
    fileprivate func getDataLocal() {
        Repository<BookSharing, BookSharingObject>
            .shared
            .getAll()
            .subscribe(onNext: { [weak self] (list) in
                self?.bookSuggestions.onNext(list)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getDataServer() {
        Observable<(CLLocationCoordinate2D, UserPrivate?, Int, Int, Bool, Bool)>
            .combineLatest(
                self.getLocation(),
                Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first },
                self.range.asObservable(),
                self.page.asObservable(),
                self.activeFindSuggest.asObservable(),
                Status.reachable.asObservable(),
                resultSelector: { ($0, $1, $2, $3, $4, $5) }
            )
            .filter { (_, _, _, _, active, status) in status && active }
            .do(onNext: { [weak self] (_) in
                self?.loading(true)
            })
            .map { (location, user, range, page, _, _) in (location, user, range, page) }
            .flatMapLatest({ (location, user, range, page) -> Observable<([BookSharing], Int)> in
                return BookNetworkService
                    .shared
                    .sugesst(user: user, currentLocation: location, range: range, page: page)
                    .catchError({ [weak self] (error) -> Observable<([BookSharing], Int)> in
                        self?.loading(false)
                        self?.activeFindSuggest.onNext(false)
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    })
            })
            .do(onNext: { [weak self] (list, range) in
                self?.loading(false)
                self?.activeFindSuggest.onNext(false)
                self?.range.onNext(range)
                guard let status = self?.showStatus, let bookSuggestions = try? self?.bookSuggestions.value(), var books = bookSuggestions else {
                    return
                }
                switch status {
                case .new:
                    books = list
                    break
                case .more:
                    books.append(contentsOf: list)
                    break
                }
                self?.bookSuggestions.onNext(books)
            })
            .map { $0.0 }
            .flatMap { Repository<BookSharing, BookSharingObject>.shared.save(objects: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getLocation() -> Observable<CLLocationCoordinate2D> {
        return LocationManager
            .manager
            .location
            .catchError { (error) -> Observable<CLLocationCoordinate2D> in
                return Repository<UserPrivate, UserPrivateObject>
                    .shared.getFirst()
                    .flatMapLatest({ (userPrivate) -> Observable<CLLocationCoordinate2D> in
                        return Observable<CLLocationCoordinate2D>.from(optional: userPrivate.profile?.location)
                    })
            }
            .map { (location) -> CLLocationCoordinate2D in
                if (location != CLLocationCoordinate2D()) {
                    return location
                } else {
                    return CLLocationCoordinate2D(latitude: 21.022736, longitude: 105.8019441)
                }
        }
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupLoading()
        self.setupCollectionView()
    }
    
    fileprivate func setupCollectionView() {
        self.registerCell()
        self.collectionView.delegate = self
        self.bookSuggestions
            .asObservable()
            .bind(to: self.collectionView.rx.items(cellIdentifier: Gat.Cell.IDENTIFIER_BOOK_COLLECTION, cellType: BookCollectionViewCell.self))
            { [weak self] (index, bookSharing, cell) in
                cell.delegate = self
                cell.backgroundColor = .clear
                cell.containerView.backgroundColor = .clear
                cell.setupBook(info: bookSharing.info!)
                cell.bookImageView.dropShadow(offset: .init(width: 6.0, height: 6.0), radius: 3.0, opacity: 0.72, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func registerCell() {
        let nib = UINib(nibName: Gat.View.BOOK_COLLECTION, bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: Gat.Cell.IDENTIFIER_BOOK_COLLECTION)
    }
    
    fileprivate func setupLoading() {
        self.layoutIfNeeded()
        if self.loadingView == nil {
            let frame = CGRect(x: self.collectionView.frame.width / 2.0 - 50.0, y: self.collectionView.frame.height / 2.0 - 25.0, width: 100.0, height: 50.0)
            self.loadingView = NVActivityIndicatorView(frame: frame, type: .ballPulseSync, color: .white, padding: 0)
            self.addSubview(self.loadingView!)
            self.bringSubviewToFront(self.loadingView!)
            self.loadingView?.color = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }

    fileprivate func loading(_ isLoading: Bool) {
        self.loadingView?.isHidden = !isLoading
    }
    
    // MARK: - Event
    fileprivate func event() {
    }
}

extension BookSuggestionTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width * (1 - 0.03 * 4) / 3, height: 250.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.03 * collectionView.frame.width, bottom: 0.0, right: 0.03 * collectionView.frame.width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

extension BookSuggestionTableViewCell: BookCollectionDelegate {
    func showBookDetail(identifier: String, sender: Any?) {
        self.controller?.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension BookSuggestionTableViewCell {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard Status.reachable.value else {
            return
        }
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.collectionView.contentOffset.y >= self.collectionView.contentSize.height - self.collectionView.frame.height {
            if transition.y < -70 {
                self.showStatus = .more
                self.page.onNext(((try? self.page.value()) ?? 1) + 1)
                self.activeFindSuggest.onNext(true)
                
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
                self.showStatus = .new
                self.range.onNext(1)
                self.page.onNext(1)
                self.activeFindSuggest.onNext(true)
            
            }
        }
    }
}
