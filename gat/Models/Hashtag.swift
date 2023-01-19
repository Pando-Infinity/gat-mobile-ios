//
//  Hashtag.swift
//  gat
//
//  Created by jujien on 9/4/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

struct Hashtag: Hashable {
    var id: Int
    var name: String
    var count: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}

extension Hashtag: ObjectConvertable {
    func asObject() -> HashtagObject {
        let object = HashtagObject()
        object.id = self.id
        object.name = self.name
        object.count = self.count
        return object
    }
}


class HashtagObject: Object {
    @objc var id: Int = 0
    @objc var name: String = ""
    @objc var count: Int = 0
    
    override class func primaryKey() -> String? { "id" }
}

extension HashtagObject: DomainConvertable {
    func asDomain() -> Hashtag {
        .init(id: self.id, name: self.name, count: self.count)
    }
}

extension HashtagObject: PrimaryValueProtocol {
    func primaryValue() -> Int {
        self.id 
    }
}
