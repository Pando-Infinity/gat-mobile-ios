//
//  Object+NextID.swift
//  gat
//
//  Created by HungTran on 4/9/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

extension Object {
    /*Lấy ID mới nhất của Object*/
    func nextId(id: String = "id") -> Int {
        let realmDB = try! Realm()
        let maxId = realmDB.objects(type(of: self).self).max(ofProperty: id) ?? 0
        return maxId + 1
    }
}


protocol DetachableObject: AnyObject {
    
    func detached() -> Self
    
}

extension Object: DetachableObject {
    
    func detached() -> Self {
        let detached = type(of: self).init()
        for property in objectSchema.properties {
            guard let value = value(forKey: property.name) else { continue }
            if let detachable = value as? DetachableObject {
                detached.setValue(detachable.detached(), forKey: property.name)
            } else {
                detached.setValue(value, forKey: property.name)
            }
        }
        return detached
    }
    
}

extension List: DetachableObject {
    
    func detached() -> List<Element> {
        let result = List<Element>()
//        forEach {
//            result.append($0.detached())
//        }
        return result
    }
    
}
