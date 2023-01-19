//
//  Extension+CLLocationCoordinate2D.swift
//  gat
//
//  Created by Vũ Kiên on 26/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func +(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D.init(latitude: lhs.latitude + rhs.latitude, longitude: lhs.longitude + rhs.longitude)
    }
    
    public static func -(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D.init(latitude: lhs.latitude - rhs.latitude, longitude: lhs.longitude - rhs.longitude)
    }
    
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude.isEqual(to: rhs.latitude) && lhs.longitude.isEqual(to: rhs.longitude)
    }
    
    func distance(to position: CLLocationCoordinate2D) -> Double {
        return sqrt(pow(self.latitude - position.latitude, 2.0) + pow(self.longitude - position.longitude, 2.0))
    }
}

extension CLLocationCoordinate2D: CustomStringConvertible {
    public var description: String {
        return "CLLocationCoordinate2D = {\n\tlatitude = \(self.latitude),\n\tlongitude = \(self.longitude)\n}"
    }
    
    
}
