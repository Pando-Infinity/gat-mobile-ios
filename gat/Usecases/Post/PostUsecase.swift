//
//  PostUsecase.swift
//  gat
//
//  Created by jujien on 10/22/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol PostUsecase {
    var post: Observable<Post> { get }
}
