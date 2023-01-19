//
//  MapView.swift
//  gat
//
//  Created by Vũ Kiên on 07/03/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import RxSwift
import RxCocoa
import CoreLocation

class MapView: UIView {
    @IBOutlet var mapView: GMSMapView!
    
    weak var viewcontroller: NearByUserController?
    fileprivate var markers: [GMSMarker] = []
    fileprivate let disposeBag = DisposeBag()
    fileprivate var positionMarker: GMSMarker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.mapView.delegate = self
        self.getLocation()
    }
    
    fileprivate func getLocation() {
        LocationManager
            .manager
            .location
            .catchError { (error) -> Observable<CLLocationCoordinate2D> in
                print(error.localizedDescription)
                return Observable.empty()
            }
            .subscribe(onNext: { [weak self] (location) in
                self?.setupMapView(latitude: location.latitude, longitude: location.longitude)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    //set up bản đồ hiển thị lên mapview
    fileprivate func setupMapView(latitude: Double, longitude: Double, zoom: Float = 14.5) {
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: zoom)
        self.mapView.camera = camera
        self.setupMarkerLocationUser(in: .init(latitude: latitude, longitude: longitude))
    }
    
    fileprivate func setupMarkerListUser(_ users: [UserPublic]) {
        for user in users {
            let markerView = UIImageView()
            markerView.frame = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
            markerView.circleCorner()
            markerView.backgroundColor = .white
            markerView.layer.borderColor = USER_MARKER_BORDER_COLOR.cgColor
            markerView.layer.borderWidth = 1.5
            markerView.layer.shadowColor = USER_MARKER_SHADOW_COLOR.cgColor
            markerView.layer.shadowRadius = 5.0
            markerView.layer.shadowOpacity = 0.4
            markerView.contentMode = .center
            if user.profile.userTypeFlag == .normal {
                markerView.image = MARKER_USER_ICON
            } else {
                markerView.image = #imageLiteral(resourceName: "bookstop-green-icon")
            }
            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: user.profile.location.latitude, longitude: user.profile.location.longitude))
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.8)
            marker.iconView = markerView
            marker.map = self.mapView
            self.markers.append(marker)
        }
    }
    
    fileprivate func setupMarkerLocationUser(in location: CLLocationCoordinate2D) {
        let markerView = UIImageView(image: MARKER_PLACE_ICON)
        markerView.frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
        markerView.circleCorner()
        markerView.backgroundColor = PLACE_BACKGROUND_COLOR
        markerView.contentMode = .center
        if self.positionMarker == nil {
            self.positionMarker = GMSMarker()
            self.positionMarker.position = location
            self.positionMarker.groundAnchor = CGPoint(x: 0.5, y: 0.8)
            self.positionMarker.iconView = markerView
            self.positionMarker.tracksViewChanges = true
        }
        self.positionMarker.map = self.mapView
    }
    
    //thêm các marker lên bản đồ
    fileprivate func setupMarker(latitude: Double, longitude: Double, iconView: UIImageView? = nil, tracksViewChanges: Bool = true) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        if let iconView = iconView {
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.8)
            marker.iconView = iconView
            marker.tracksViewChanges = tracksViewChanges
        }
        marker.map = self.mapView
    }
    
    //MARK: - Event
    func event() {
        self.eventListUsersChanged()
    }
    
    fileprivate func eventListUsersChanged() {
        self.viewcontroller?
            .users
            .subscribe(onNext: { [weak self] (users) in
                self?.mapView.clear()
                self?.markers = []
                self?.setupMarkerListUser(users)
                if self?.positionMarker != nil {
                    self?.positionMarker.map = self?.mapView
                }
            })
            .disposed(by: self.disposeBag)
    }
}

extension MapView: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        self.viewcontroller?.locationInEdgeMap.onNext((mapView.projection.visibleRegion().farRight, mapView.projection.visibleRegion().nearLeft))
    }
}
