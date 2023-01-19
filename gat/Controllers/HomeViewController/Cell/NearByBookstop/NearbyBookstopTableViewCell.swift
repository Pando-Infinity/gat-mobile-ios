//
//  NearbyBookstopTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import CoreLocation

class NearbyBookstopTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let bookstops = BehaviorSubject<[Bookstop]>(value: [])
    
    weak var delegate: HomeDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.getData()
        self.setupUI()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable<(CLLocationCoordinate2D, Bool)>
            .combineLatest(self.getLocation(), Status.reachable.asObservable(), resultSelector: { ($0, $1) })
            .filter { (_, status) in status }
            .map { (location, _ ) in location }
            .flatMapLatest {
                BookstopNetworkService.shared.findBookstop(location: $0)
                    .catchError({ (error) -> Observable<[Bookstop]> in
                        HandleError.default.showAlert(with: error)
                        return Observable<[Bookstop]>.empty()
                    })
            }
            .subscribe(self.bookstops)
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
        self.collectionView.delegate = self
        self.registerCell()
        self.setupCollectionView()
    }
    
    fileprivate func registerCell() {
        let nib = UINib(nibName: "NearByBookstopCollectionViewCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "nearbyBookstopCollectionCell")
    }
    
    fileprivate func setupCollectionView() {
        self.bookstops
            .asObservable()
            .bind(to: self.collectionView.rx.items(cellIdentifier: "nearbyBookstopCollectionCell", cellType: BoxCollectionViewCell.self))
            { [weak self] (index, bookstop, cell) in
                cell.delegate = self
                cell.setup(bookstop: bookstop)
            }
            .disposed(by: self.disposeBag)
    }
    
}

extension NearbyBookstopTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: collectionView.frame.width * 0.65, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
    }
}

extension NearbyBookstopTableViewCell: BoxCollectionCellDelegate {
    func showView(identifire: String, sender: Any?) {
        self.delegate?.showView(identifier: identifire, sender: sender)
    }
    
    
}
