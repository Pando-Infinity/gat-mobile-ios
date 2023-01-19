//
//  MapViewController.swift
//  gat
//
//  Created by HungTran on 2/27/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import RealmSwift
import GoogleMaps
import GooglePlaces
import FirebaseAnalytics

protocol MapDelegate: class {
    
    func update(address: String)
    
    func update(location: CLLocationCoordinate2D)
}

class MapViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var searchAddressLabel: UILabel!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var containerMapView: GMSMapView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var searchLeadingLowConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchLeadingHighConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    weak var delegate: MapDelegate?
    let isEditMap = BehaviorSubject<Bool>(value: true)
    let isUpdating = BehaviorSubject<Bool>(value: false)
    let currentLocation = BehaviorSubject<CLLocationCoordinate2D>(value: .init())
    let currentAddress = BehaviorSubject<String>(value: "")
    fileprivate let disableGetAddress = BehaviorSubject<Bool>(value: true)
    fileprivate let sendRequest: BehaviorSubject<Bool> = .init(value: false)
    fileprivate var zoomMap: Float = 14.0
    fileprivate var markerPosition: GMSMarker?
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - LifeTime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.sendLocation()
        self.getLocation()
        self.getAddress()
        self.event()
    }
    
    // MARK: - Send Location
    fileprivate func sendLocation() {
        Observable<(CLLocationCoordinate2D, String, Bool)>
            .combineLatest(self.currentLocation, self.currentAddress, self.sendRequest, resultSelector: { ($0, $1, $2) })
            .filter { (_, _, status) in status }
            .map { (location, address, _) in (location, address) }
            .filter { _ in Status.reachable.value }
            .withLatestFrom(Repository<UserPrivate, UserPrivateObject>.shared.getFirst()) { (arg0, userPrivate) -> UserPrivate in
                let (location, address) = arg0
                userPrivate.profile?.location = location
                userPrivate.profile?.address = address
                return userPrivate
            }
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.view.isUserInteractionEnabled = false
            })
            .flatMapLatest { [weak self] (userPrivate) in
                Observable<((), UserPrivate)>
                    .combineLatest(
                        UserNetworkService
                            .shared
                            .updateInfo(user: userPrivate)
                            .catchError({ [weak self] (error) -> Observable<()> in
                                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                                self?.view.isUserInteractionEnabled = false
                                HandleError.default.showAlert(with: error, action: { [weak self] in
                                    self?.goToHome()
                                })
                                return Observable.empty()
                            }),
                        Observable<UserPrivate>.just(userPrivate),
                        resultSelector: { ($0, $1) }
                    )
            }
            .map { (_, userPrivate) in userPrivate }
            .flatMapLatest { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .withLatestFrom(self.isUpdating)
            .subscribe(onNext: { [weak self] (isUpdating) in
                if isUpdating {
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    self?.view.isUserInteractionEnabled = false
                    self?.goToHome()
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Location
    fileprivate func getLocation() {
        self.getCurrentLocation()
        self.getMyLocation()
    }
    
    fileprivate func getAddress() {
        Observable<(CLLocationCoordinate2D, Bool)>
            .combineLatest(self.currentLocation.filter { $0 != CLLocationCoordinate2D() }, self.disableGetAddress, resultSelector: {($0, $1)})
            .filter { (_, disable) in !disable}
            .map { (position, _) in position }
            .flatMap { (position) -> Observable<String> in
                return Observable<String>.create({ (observer) -> Disposable in
                    let coder = GMSGeocoder()
                    coder.reverseGeocodeCoordinate(position, completionHandler: { (response, error) in
                        if let error = error {
                            observer.onError(error)
                        }
                        if let address = response?.results()?.first?.lines?.first {
                            observer.onNext(address)
                        }
                    })
                    return Disposables.create()
                })
            }
            .catchError { (error) -> Observable<String> in
                return Observable.empty()
            }
            .subscribe(self.currentAddress)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getCurrentLocation() {
        Observable<(CLLocationCoordinate2D, Bool)>
            .combineLatest(self.currentLocation.filter { $0 != CLLocationCoordinate2D() }, LocationManager.manager.permission.asObservable(), resultSelector: { ($0, $1) })
            .filter { (_, permission) in permission }
            .map { (position, _) in position }
            .subscribeOn(MainScheduler.asyncInstance)
            .bind { [weak self] (position) in
                self?.createMapView(with: position)
                self?.addMarker(in: position)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getMyLocation() {
        Observable<(CLLocationCoordinate2D, Bool, Bool)>
            .combineLatest(LocationManager.manager.location, self.isEditMap, LocationManager.manager.permission.asObservable(), resultSelector: { ($0, $1, $2) })
            .filter { (_, isEditing, permission) in !isEditing && permission }
            .map { (position, _, _) in position }
            .elementAt(0)
            .subscribe(onNext: { [weak self] (position) in
                self?.createMapView(with: position)
                self?.addMarker(in: position)
                self?.currentLocation.onNext(position)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupMapView()
        self.setupButton()
        self.setupAddress()
        self.setupBackButton()
    }
    
    fileprivate func setupMapView() {
        self.view.layoutIfNeeded()
        self.containerMapView.delegate = self
        self.containerMapView.settings.myLocationButton = true
        self.containerMapView.isMyLocationEnabled = true
        self.containerMapView.padding = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 50.0, right: 8.0)
    }
    
    fileprivate func setupBackButton() {
        self.isEditMap
            .bind { [weak self] (isEditing) in
                self?.backButton.isHidden = !isEditing
                if isEditing {
                    self?.searchLeadingLowConstraint.priority = UILayoutPriority.defaultHigh
                    self?.searchLeadingHighConstraint.priority = UILayoutPriority.defaultLow
                } else {
                    self?.searchLeadingLowConstraint.priority = UILayoutPriority.defaultLow
                    self?.searchLeadingHighConstraint.priority = UILayoutPriority.defaultHigh
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupButton() {
        self.actionButton.setTitle(Gat.Text.Map.SAVE_ADDRESS_TITLE.localized(), for: .normal)
        self.view.layoutIfNeeded()
        self.actionButton.cornerRadius(radius: self.actionButton.frame.height / 2.0)
    }
    
    fileprivate func setupAddress() {
        self.currentAddress
            .bind(to: self.searchAddressLabel.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func createMapView(with position: CLLocationCoordinate2D) {
        let camera = GMSCameraPosition.camera(withLatitude: position.latitude, longitude: position.longitude, zoom: self.zoomMap)
        self.containerMapView.animate(to: camera)
    }
    
    fileprivate func addMarker(in position: CLLocationCoordinate2D, icon: UIImage? = #imageLiteral(resourceName: "MapMarker")) {
        if self.markerPosition == nil {
            self.markerPosition = GMSMarker(position: position)
            self.markerPosition?.icon = icon
            self.markerPosition?.appearAnimation = .pop
            self.markerPosition?.map = self.containerMapView
        } else {
            self.markerPosition?.position = position
        }
    }

    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.actionEvent()
        self.showListAddess()
        self.permissionLocation()
    }
    
    fileprivate func permissionLocation() {
        LocationManager
            .manager
            .permission
            .asObservable()
            .bind {  (permission) in
                guard let vc = UIApplication.topViewController(), !permission else {
                    return
                }
                let actionSetting = ActionButton(titleLabel: Gat.Text.Home.SETTING_ALERT_TITLE.localized(), action: {
                    guard let url = URL(string: Gat.Prefs.OPEN_PRIVACY) else {
                        return
                    }
                    guard UIApplication.shared.canOpenURL(url) else {
                        return
                    }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                })
                AlertCustomViewController.showAlert(title: Gat.Text.Home.ERROR_ALERT_TITLE.localized(), message: Gat.Text.CommonError.ERROR_GPS_MESSAGE.localized(), actions: [actionSetting], in: vc)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func backEvent() {
        self.backButton
            .rx
            .controlEvent(.touchUpInside)
            .bind { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showListAddess() {
        self.searchView
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                let vc = GMSAutocompleteViewController()
                vc.tableCellBackgroundColor = .white
                vc.tableCellSeparatorColor = .lightGray
                vc.primaryTextColor = .gray
                vc.primaryTextHighlightColor = .black
                
                vc.delegate = self
                self?.present(vc, animated: true, completion: nil)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func actionEvent() {
        self.saveLocationAndAddress()
        self.sendLocationEvent()
    }
    
    fileprivate func sendLocationEvent() {
        self.actionButton
            .rx
            .tap
            .asObservable()
            .withLatestFrom(self.isEditMap)
            .filter { !$0 }
            .map { !$0 }
            .subscribe(onNext: { [weak self] (status) in
                self?.sendRequest.onNext(status)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func saveLocationAndAddress() {
        self.actionButton.rx
            .controlEvent(.touchUpInside)
            .flatMap { [weak self] (_) -> Observable<(CLLocationCoordinate2D, String, Bool)> in
                return Observable<(CLLocationCoordinate2D, String, Bool)>.combineLatest(self?.currentLocation ?? Observable.empty(), self?.currentAddress ?? Observable.empty(), self?.isEditMap ?? Observable.empty(), resultSelector: {($0, $1, $2)})
            }
            .filter { (_, _, isEditing) in isEditing }
            .map { (location, address, _) in (location, address)}
            .subscribe(onNext: { [weak self] (location, address) in
                self?.delegate?.update(location: location)
                self?.delegate?.update(address: address)
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func goToHome() {
        let storyboard = UIStoryboard.init(name: Gat.Storyboard.Main, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Home")
        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = vc
    }
    
}

extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.zoomMap = mapView.camera.zoom
        self.currentLocation.onNext(coordinate)
        self.disableGetAddress.onNext(false)
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        self.zoomMap = position.zoom
        do {
            let disable = try self.disableGetAddress.value()
            if !disable {
                self.currentLocation.onNext(position.target)
            }
        } catch {
        }
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        self.disableGetAddress.onNext(!gesture)
    }
}

extension MapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MapViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        if let address = place.formattedAddress {
            self.currentAddress.onNext(address)
            self.disableGetAddress.onNext(true)
            let client = GMSPlacesClient.init()
            client.lookUpPlaceID(place.placeID ?? "") { (p, error) in
                self.currentLocation.onNext(p?.coordinate ?? CLLocationCoordinate2D())
            }
        }
        viewController.dismiss(animated: false, completion: nil)
    }
    
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        viewController.dismiss(animated: false, completion: nil)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        
    }
}

