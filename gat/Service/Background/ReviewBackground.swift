//
//  ReviewBackground.swift
//  gat
//
//  Created by Vũ Kiên on 28/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

class ReviewBackground {
    
    static let shared = ReviewBackground()
    fileprivate let startDelete: BehaviorSubject<Bool> = .init(value: false)
    
    fileprivate init() {
        
    }
    
    func configure() -> Observable<()> {
        return self.startDelete
            .filter { $0 }
            .flatMapLatest { _ in Repository<Review, ReviewObject>.shared.getAll(predicateFormat: "deleteFlag = %@", args: [true]) }
            .flatMapLatest { Observable<Review>.from($0) }
            .filter { _ in Status.reachable.value }
            .flatMapLatest {
                Observable<((), Review)>
                    .combineLatest(
                        ReviewNetworkService.shared.remove(review: $0),
                        Observable<Review>.just($0),
                        resultSelector: { ($0, $1) }
                )
            }
            .map { (_, instance) in instance }
            .flatMapLatest { Repository<Review, ReviewObject>.shared.delete(object: $0) }
    }
    
    func delete(_ status: Bool = true) {
        self.startDelete.onNext(status)
    }
}
