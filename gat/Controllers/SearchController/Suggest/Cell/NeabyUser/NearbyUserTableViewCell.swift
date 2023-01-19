//
//  ShareTableViewCell.swift
//  Gatbook
//
//  Created by GaT-Kien on 2/21/17.
//  Copyright © 2017 GaT-Kien. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SwiftyJSON
import CoreLocation
import NVActivityIndicatorView

class NearByUserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var loadingView: NVActivityIndicatorView!

    weak var controller: SuggestViewController?
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.getData()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable<(CLLocationCoordinate2D, Bool)>
            .combineLatest(self.getLocation(), Status.reachable.asObservable(), resultSelector: {($0, $1)})
            .filter { (_, status) in status}
            .map { (location, _ ) in location }
            .do(onNext: { [weak self] (_) in
                self?.loading(true)
            })
            .flatMapLatest({ [weak self] (location) -> Observable<([UserPublic], Int?)> in
                return SearchNetworkService
                    .shared
                    .findNearBy(currentLocation: location, northEast: CLLocationCoordinate2D(latitude: location.latitude + 0.0064, longitude: location.longitude + 0.0097), southWest: CLLocationCoordinate2D(latitude: location.latitude - 0.0064, longitude: location.longitude - 0.0097))
                    .catchError({ [weak self] (error) -> Observable<([UserPublic], Int?)> in
                        HandleError.default.showAlert(with: error)
                        self?.loading(false)
                        return Observable.empty()
                    })
            })
            .subscribeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] (_) in
                self?.loading(false)
            })
            .map { (users, _) in users }
            .bind(to: self.collectionView.rx.items(cellIdentifier: Gat.Cell.IDENTIFIER_USER_COLLECTION, cellType: UserCollectionViewCell.self))
            { (index, user, cell) in
                cell.setupUser(user)
            }
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
                    return CLLocationCoordinate2D.init(latitude: 21.022736, longitude: 105.8019441)
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
    }
    
    fileprivate func registerCell() {
        let nib = UINib(nibName: Gat.View.USER_COLLECTION_CELL, bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: Gat.Cell.IDENTIFIER_USER_COLLECTION)
    }
    
    fileprivate func setupLoading() {
    }
    
    fileprivate func loading(_ isLoading: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = isLoading
        //self.loadingView?.isHidden = !isLoading
    }
    
    fileprivate func event() {
        self.collectionView
            .rx
            .modelSelected(UserPublic.self)
            .flatMapLatest {
                Observable<(UserPublic, UserPrivate?)>
                    .combineLatest(
                        Observable<UserPublic>.just($0),
                        Repository<UserPrivate, UserPrivateObject>.shared.getAll().map { $0.first },
                        resultSelector: { ($0, $1) }
                    )
            }
            .subscribe(onNext: { [weak self] (userPublic, userPrivate) in
                if let userId = userPrivate?.id, userId == userPublic.profile.id {
                    let storyboard = UIStoryboard.init(name: Gat.Storyboard.PERSON, bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                    vc.isShowButton.onNext(true)
                    vc.hidesBottomBarWhenPushed = true
                    self?.controller?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    print(userPublic.profile.userTypeFlag)
                    switch userPublic.profile.userTypeFlag {
                    case .normal:
                        self?.controller?.performSegue(withIdentifier: Gat.Segue.SHOW_USERPAGE_IDENTIFIER, sender: userPublic)
                        break
                    case .bookstop:
                        let bookstop = Bookstop()
                        bookstop.id = userPublic.profile.id
                        bookstop.profile = userPublic.profile
                        self?.controller?.performSegue(withIdentifier: Gat.Segue.SHOW_BOOKSTOP_IDENTIFIER, sender: bookstop)
                        break
                    case .organization:
                        let bookstop = Bookstop()
                        bookstop.id = userPublic.profile.id
                        bookstop.profile = userPublic.profile
                        self?.controller?.performSegue(withIdentifier: "showBookstopOrganization", sender: bookstop)
                        break
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }

}

extension NearByUserTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: self.frame.width * 0.14, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
    }
}
