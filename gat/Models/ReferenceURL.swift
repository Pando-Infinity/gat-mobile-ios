//
//  ReferenceURL.swift
//  gat
//
//  Created by jujien on 8/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

struct ReferenceURL {
    var id: String
    var localURL: URL
    var serverURL: URL
    var createDate: Date
}

extension ReferenceURL: ObjectConvertable {
    func asObject() -> ReferenceURLObject {
        let object = ReferenceURLObject()
        object.id = self.id
        object.localURL = self.localURL.absoluteString
        object.serverURL = self.serverURL.absoluteString
        object.createDate = self.createDate
        return object
    }
}

class ReferenceURLObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var localURL: String = ""
    @objc dynamic var serverURL: String = ""
    @objc dynamic var createDate: Date = .init()
    
    override class func primaryKey() -> String? { "id" }
}

extension ReferenceURLObject: DomainConvertable {
    func asDomain() -> ReferenceURL {
        .init(id: self.id, localURL: URL(string: self.localURL)!, serverURL: URL(string: self.serverURL)!, createDate: self.createDate)
    }
}

extension ReferenceURLObject: PrimaryValueProtocol {
    func primaryValue() -> String { self.id }
}


