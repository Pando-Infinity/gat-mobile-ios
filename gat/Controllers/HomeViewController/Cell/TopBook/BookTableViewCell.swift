//
//  BookTableViewCell.swift
//  Gatbook
//
//  Created by GaT-Kien on 2/21/17.
//  Copyright © 2017 GaT-Kien. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NVActivityIndicatorView
import CoreLocation

class BookTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var loadingView: NVActivityIndicatorView?
    
    weak var delegate: HomeDelegate?
    fileprivate let sharingBooks = BehaviorSubject<[BookSharing]>(value: [])
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupUI()
        self.getData()
        self.event()
    }
    
    
    //MARK: - Data
    fileprivate func getData() {
        self.getDataLocal()
        self.getDataServer()
    }
    
    fileprivate func getDataServer() {
        Status
            .reachable
            .asObservable()
            .filter { $0 }
            .do(onNext: { [weak self] (_) in
                self?.loadingView?.isHidden = false
                self?.messageLabel.isHidden = true
            })
            .flatMapLatest({ [weak self] (_) -> Observable<[BookSharing]> in
                return BookNetworkService.shared.topBorrow(previousDay: Int(AppConfig.sharedConfig.config(item: "previous_days")!)!, page: 1)
                    .catchError { [weak self] (error) -> Observable<[BookSharing]> in
                        HandleError.default.showAlert(with: error, action: { [weak self] in
                            self?.loadingView?.isHidden = true
                            self?.messageLabel.isHidden = false
                        })
                        return Observable<[BookSharing]>.empty()
                }
            })
            .filter { !$0.isEmpty }
            .do(onNext: { [weak self] (bookSharings) in
                self?.loadingView?.isHidden = true
                self?.sharingBooks.onNext(bookSharings)
                
            })
            .flatMapLatest { Repository<BookSharing, BookSharingObject>.shared.save(objects: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getDataLocal() {
        Repository<BookSharing, BookSharingObject>
            .shared
            .getAll()
            .do(onNext: { [weak self] (bookSharings) in
                self?.sharingBooks.onNext(bookSharings)
            })
            .flatMapLatest { Repository<BookSharing, BookSharingObject>.shared.delete(objects: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.collectionView.backgroundColor = .white
        self.backgroundColor = .white
        self.setupCollectionViewCell()
        self.setupCollectionView()
        self.setupMessage()
        self.loading()
    }

    fileprivate func setupCollectionViewCell() {
        let nib = UINib(nibName: Gat.View.BOOK_COLLECTION, bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: Gat.Cell.IDENTIFIER_BOOK_COLLECTION)
        self.collectionView.delegate = self
    }

    fileprivate func setupMessage() {
        self.messageLabel.text = Gat.Text.Home.ERROR_BOOKS_EMPTY_MESSAGE.localized()
        self.messageLabel.isHidden = true
    }

    fileprivate func setupCollectionView() {
        self.sharingBooks
            .asObservable()
            .bind(to: self.collectionView.rx.items(cellIdentifier: Gat.Cell.IDENTIFIER_BOOK_COLLECTION, cellType: BookCollectionViewCell.self)) { [weak self] (index, bookSharing, cell) in
                cell.delegate = self
                cell.containerView.dropShadow(offset: .zero, radius: 5.0, opacity: 0.5, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
                cell.setupBook(info: bookSharing.info!)
            }
            .disposed(by: self.disposeBag)
    }

    fileprivate func loading() {
        self.layoutIfNeeded()
        if self.loadingView == nil {
            let frame = CGRect(x: self.collectionView.frame.width / 2.0 - 50.0, y: self.collectionView.frame.height / 2.0 - 25.0, width: 100.0, height: 50.0)
            self.loadingView = NVActivityIndicatorView(frame: frame, type: .ballPulseSync, color: .white, padding: 0)
            self.loadingView?.color = #colorLiteral(red: 0.5568627451, green: 0.7647058824, blue: 0.8745098039, alpha: 1)
            self.addSubview(self.loadingView!)
            self.bringSubviewToFront(self.loadingView!)
        }
    }

    //MARK: - Event
    func event() {
        
    }
}

extension BookTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width * 124.0 / 375.0 , height: collectionView.frame.height )
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

extension BookTableViewCell: BookCollectionDelegate {
    func showBookDetail(identifier: String, sender: Any?) {
        self.delegate?.showView(identifier: identifier, sender: sender)
    }
    
    
}
