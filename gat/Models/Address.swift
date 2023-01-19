//
//  Address.swift
//  gat
//
//  Created by HungTran on 3/21/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import SwiftyJSON

class Address: Object {
    @objc dynamic var id: Int = -1
    
    @objc dynamic var address: String = ""
    @objc dynamic var locationType: Int = 0
    @objc dynamic var latitude: Float = 0
    @objc dynamic var longitude: Float = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    /**Trả về đối tượng Address từ JSON*/
    static func parseFrom(json: JSON) -> Address? {
        guard let id = json["locationId"].int else {
            return nil
        }
        if let address = try! Realm().object(ofType: Address.self, forPrimaryKey: id) {
            try! Realm().safeWrite {
                if json["address"].exists(), let tmpAddress = json["address"].string {
                    address.address = tmpAddress
                }
                if json["locationType"].exists(), let locationType = json["locationType"].int {
                    address.locationType = locationType
                }
                if json["latitude"].exists(), let latitude = json["latitude"].float {
                    address.latitude = latitude
                }
                if json["longitude"].exists(), let longitude = json["longitude"].float {
                    address.longitude = longitude
                }
            }
            return address
        } else {
            let address = Address()
            address.id = id
            address.address = json["address"].string ?? ""
            address.locationType = json["locationType"].int ?? 0
            address.latitude = json["latitude"].float ?? 0.0
            address.longitude = json["longitude"].float ?? 0.0
            return address
        }
    }
}
