//
//  ReadingBookDetailViewModel.swift
//  gat
//
//  Created by jujien on 1/30/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class ReadingBookDetailViewModel {
    let reading: BehaviorRelay<ReadingBook>
    
    init(reading: ReadingBook) {
        self.reading = .init(value: reading)
    }
}
