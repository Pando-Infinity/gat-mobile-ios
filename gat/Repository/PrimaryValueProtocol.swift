//
//  PrimaryValueProtocol.swift
//  gat
//
//  Created by Vũ Kiên on 05/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation

protocol PrimaryValueProtocol: class {
    associatedtype K
    
    func primaryValue() -> K
}
