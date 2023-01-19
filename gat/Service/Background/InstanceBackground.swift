//
//  InstanceBackground.swift
//  gat
//
//  Created by Vũ Kiên on 27/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

class InstanceBackground {
    
    static let shared = InstanceBackground()
    fileprivate let startDelete: BehaviorSubject<Bool> = .init(value: false)
    
    fileprivate init() {
        
    }

    func configure() -> Observable<()> {
        return self.startDelete
            .filter { $0 }
            .flatMapLatest { _ in Repository<Instance, InstanceObject>.shared.getAll(predicateFormat: "deleteFlag = %@", args: [true]) }
            .flatMapLatest { Observable<Instance>.from($0) }
            .filter { _ in Status.reachable.value }
            .flatMapLatest {
                Observable<((), Instance)>
                    .combineLatest(
                        InstanceNetworkService.shared.remove(instance: $0)
                            .catchError { (error) -> Observable<()> in
                                return Observable.empty()
                        },
                        Observable<Instance>.just($0),
                        resultSelector: { ($0, $1) }
                    )
            }
            .map { (_, instance) in instance }
            .flatMapLatest { Repository<Instance, InstanceObject>.shared.delete(object: $0) }
    }
    
    func delete(_ status: Bool = true) {
        self.startDelete.onNext(status)
    }
    
}
