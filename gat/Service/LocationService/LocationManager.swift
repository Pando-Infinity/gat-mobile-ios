//
//  LocationManager.swift
//  gat
//
//  Created by Vũ Kiên on 08/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import CoreLocation
import RxSwift

class LocationManager: NSObject {

    static let manager = LocationManager()
    fileprivate var locationManager: CLLocationManager!
    fileprivate var lastLocation: CLLocation!
    fileprivate var disposeBag = DisposeBag()
    fileprivate let coordinateSubject = BehaviorSubject<CLLocationCoordinate2D>(value: CLLocationCoordinate2D())
    var permission: Variable<Bool> = Variable<Bool>(true)
    var location: Observable<CLLocationCoordinate2D>!
    
    fileprivate override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locationManager.distanceFilter = 100.0
        self.locationManager.delegate = self
        self.location = self.coordinateSubject.asObservable().filter { $0 != CLLocationCoordinate2D() }
        self.event()
    }
    
    fileprivate func event() {
        self.permission.asObservable().bind { [weak self] (permission) in
            if permission {
                self?.startUpdate()
            } else {
                self?.locationManager.stopUpdatingLocation()
            }
        }.disposed(by: self.disposeBag)
    }
    
    func startUpdate() {
        self.locationManager.startMonitoringVisits()
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    static func getAreaLocation() -> (CLLocationCoordinate2D, CLLocationCoordinate2D, CLLocationCoordinate2D) {
        return (CLLocationCoordinate2D(), CLLocationCoordinate2D(), CLLocationCoordinate2D())
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last!
        if location.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        if location.horizontalAccuracy < 0 {
            return
        }
        if self.lastLocation == nil || self.lastLocation.horizontalAccuracy > location.horizontalAccuracy {
            self.lastLocation = location
            if self.lastLocation.horizontalAccuracy <= self.locationManager.desiredAccuracy {
                self.coordinateSubject.onNext(self.lastLocation.coordinate)
            } else {
                self.coordinateSubject.onNext(location.coordinate)
            }
        } else {
            self.coordinateSubject.onNext(location.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error.localizedDescription)")
        self.coordinateSubject.onError(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied:
            self.permission.value = false
            break
        case .restricted:
            self.permission.value = false
            break
        default:
            self.permission.value = true
            break
        }
    }
}
