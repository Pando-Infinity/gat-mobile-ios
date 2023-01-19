//
//  SelectCategoryPostPresenter.swift
//  gat
//
//  Created by jujien on 9/3/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa


protocol SelectCategoryPostPresenter {
    var categories: Observable<[PostCategory]> { get }
    
    var selected: BehaviorRelay<PostCategory?> { get set }
    
    func search(title: String)
    
    func next()
    
    func refresh()
}

struct SimpleSelectCategoryPostPresenter: SelectCategoryPostPresenter {
    var categories: Observable<[PostCategory]> { self.items.asObservable() }
    
    var selected: BehaviorRelay<PostCategory?>
    
    fileprivate let items: BehaviorRelay<[PostCategory]> = .init(value: [])
    fileprivate let param: BehaviorRelay<DefaultParam> = .init(value: .init(text: nil, pageNum: 1))
    fileprivate let page = BehaviorRelay<Int>(value: 1)
    fileprivate let disposeBag = DisposeBag()
    
    init(selected: PostCategory?) {
        self.selected = .init(value: selected)
        self.param
            .flatMap { PostService.shared.categories(title: $0.text ?? "", pageNum: $0.pageNum, pageSize: $0.pageSize).catchErrorJustReturn([]) }
            .withLatestFrom(self.param.asObservable(), resultSelector: { ($0, $1) })
            .withLatestFrom(self.items.asObservable()) { (arg0, items) -> [PostCategory] in
                let (result, param) = arg0
                var items = items
                if param.pageNum == 1 {
                    items = result
                } else {
                    items.append(contentsOf: result)
                }
                return items
            }
        .subscribe(onNext: self.items.accept)
        .disposed(by: self.disposeBag)
    
        
    }
    
    func search(title: String) {
        self.param.accept(.init(text: title, pageNum: 1))
    }
    
    func next() {
        self.param.accept(.init(text: self.param.value.text, pageNum: self.param.value.pageNum + 1, pageSize: self.param.value.pageSize))
//        self.page.accept(self.page.value + 1)
    }
    
    func refresh() {
        self.param.accept(.init(text: self.param.value.text, pageNum: 1, pageSize: self.param.value.pageSize))
//        self.page.accept(1)
    }
}
