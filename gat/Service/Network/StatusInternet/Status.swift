//
//  Status.swift
//  gat
//
//  Created by Vũ Kiên on 28/02/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import Reachability
import RxSwift
import RxCocoa

class Status {
    static var reachable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    
    fileprivate var reachability: Reachability?
    fileprivate static var `default`: Status = Status()
    
    fileprivate init() {
        self.reachability = Reachability()
        
        //Khi co ket noi
        self.reachability?.whenReachable = {
            _ in
            Status.reachable.accept(true)
        }
        
        //Khi khong co ket noi
        self.reachability?.whenUnreachable = {
            _ in
            Status.reachable.accept(false)
        }
    }
    
    ///Bat Check ket noi internet
    class func start() throws {
        try Status.default.reachability?.startNotifier()
    }
    
    ///Tat check ket noi
    class func stop() {
        Status.default.reachability?.stopNotifier()
    }
}
