//
//  File.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

protocol DomainConvertable {
    associatedtype Domain
    
    func asDomain() -> Domain
}

protocol ObjectConvertable {
    associatedtype Object: RealmSwift.Object
    
    func asObject() -> Object
}
