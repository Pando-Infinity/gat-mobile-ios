//
//  BookSuggestModeTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 30/08/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import CoreLocation

class BookSuggestModeTableViewCell: UITableViewCell {
    
    class var identifier: String {
        return "suggestModeCell"
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let mode: BehaviorSubject<SuggestBookByModeRequest.SuggestBookMode> = .init(value: .topBorrowing)
    weak var delegate: HomeDelegate?
    fileprivate let disposeBag = DisposeBag()
    fileprivate let bookSharings: BehaviorSubject<[BookSharing]> = .init(value: [])

    override func awakeFromNib() {
        super.awakeFromNib()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable<(SuggestBookByModeRequest.SuggestBookMode, CLLocationCoordinate2D, Bool)>
            .combineLatest(self.mode, self.getLocation(), Status.reachable.asObservable(), resultSelector: { ($0, $1, $2) })
            .filter { $0.2 }
            .map { ($0.0, $0.1) }
            .flatMap { (mode, location) -> Observable<[BookSharing]> in
                return BookNetworkService
                    .shared
                    .sugesst(mode: mode, previousDays: Int(AppConfig.sharedConfig.config(item: "previous_days")!)!, location: location)
                    .catchError({ (error) -> Observable<[BookSharing]> in
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                })
            }
            .subscribe(self.bookSharings)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getLocation() -> Observable<CLLocationCoordinate2D> {
        return LocationManager
            .manager
            .location
            .catchErrorJustReturn(CLLocationCoordinate2D())
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.collectionView.delegate = self 
        self.collectionView.register(UINib.init(nibName: BookCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: "BookCollectionCell")
        self.bookSharings
            .bind(to: self.collectionView.rx.items(cellIdentifier: "BookCollectionCell", cellType: BookCollectionViewCell.self))
            { [weak self] (index, bookSharing, cell) in
                cell.setupBook(info: bookSharing.info!)
                cell.containerView.dropShadow(offset: .zero, radius: 5.0, opacity: 0.5, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
                cell.delegate = self
            }
            .disposed(by: self.disposeBag)
    }

    // MARK: - Event
    fileprivate func event() {
        self.collectionViewEvent()
    }
    
    fileprivate func collectionViewEvent() {
    }
}

extension BookSuggestModeTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width / 3.5, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
    }
}

extension BookSuggestModeTableViewCell: BookCollectionDelegate {
    func showBookDetail(identifier: String, sender: Any?) {
        self.delegate?.showView(identifier: identifier, sender: sender)
    }
}
