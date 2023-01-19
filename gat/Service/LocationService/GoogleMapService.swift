//
//  GoogleMapService.swift
//  gat
//
//  Created by Vũ Kiên on 19/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import GoogleMaps
import GooglePlaces
import RxSwift

class GoogleMapService {
    static let `default` = GoogleMapService()
    
    fileprivate init() {
        
    }
    
    func address(in location: CLLocationCoordinate2D) -> Observable<String> {
        return Observable<String>
            .create({ (observer) -> Disposable in
                let geoCoder = GMSGeocoder()
                geoCoder.reverseGeocodeCoordinate(location, completionHandler: { (response, error) in
                    if let error = error {
                        observer.onError(ServiceError.init(domain: "", code: -1, userInfo: ["message": error.localizedDescription]))
                    }
                    var address = ""
                    if let thoroughfare = response?.results()?.first?.thoroughfare {
                        address += thoroughfare + ", "
                    }
                    if let subLocality = response?.results()?.first?.subLocality {
                        address += subLocality + ", "
                    }
                    if let city = response?.results()?.first?.locality {
                        address += city + ", "
                    }
                    if let area = response?.results()?.first?.administrativeArea {
                        address += area + ", "
                    }
                    if let country = response?.results()?.first?.country {
                        address += country
                    }
                    observer.onNext(address)
                })
                return Disposables.create()
            })
    }
    
    func address() -> Observable<String> {
        return LocationManager.manager.location.flatMap({ (location) -> Observable<String> in
            return Observable<String>.create({ (observer) -> Disposable in
                let geoCoder = GMSGeocoder()
                geoCoder.reverseGeocodeCoordinate(location, completionHandler: { (response, error) in
                    if let error = error {
                        observer.onError(ServiceError.init(domain: "", code: -1, userInfo: ["message": error.localizedDescription]))
                    }
                    var address = ""
                    if let thoroughfare = response?.results()?.first?.thoroughfare {
                        address += thoroughfare + ", "
                    }
                    if let subLocality = response?.results()?.first?.subLocality {
                        address += subLocality + ", "
                    }
                    if let city = response?.results()?.first?.locality {
                        address += city + ", "
                    }
                    if let area = response?.results()?.first?.administrativeArea {
                        address += area + ", "
                    }
                    if let country = response?.results()?.first?.country {
                        address += country
                    }
                    observer.onNext(address)
                })
                return Disposables.create()
            })
        })
    }
    
}
