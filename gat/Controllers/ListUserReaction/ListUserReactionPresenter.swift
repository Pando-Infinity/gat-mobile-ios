//
//  ListUserReactionPresenter.swift
//  gat
//
//  Created by jujien on 11/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa



protocol ListUserReactionPresenter {
    var users: Observable<[UserReactionInfo]> { get }
    
    var subTitle: Observable<String> { get }
    
    func next()
    
    func refresh()
}

struct SimpleListUserReactionPresenter: ListUserReactionPresenter {
    var users: Observable<[UserReactionInfo]> { self.userReactions.asObservable() }
    
    var subTitle: Observable<String> {
        Observable.combineLatest(self.totalUser.asObservable(), self.totalReaction.asObservable())
            .filter { $0.0 != 0 && $0.1 != 0 }
            .map { (totalUser, totalReaction) -> String in
                return String(format:"NUMBER_REACTION_BY_MEMBER_TITLE".localized(),totalReaction,totalUser)
            }
        
    }
    
    fileprivate let userReactions: BehaviorRelay<[UserReactionInfo]> = .init(value: [])
    fileprivate let totalUser: BehaviorRelay<Int> = .init(value: 0)
    fileprivate let totalReaction: BehaviorRelay<Int>
    fileprivate let param = BehaviorRelay<DefaultParam>(value: .init(pageNum: 1))
    fileprivate let disposeBag = DisposeBag()
    
    init(kind: ListUserReactionKind, totalReaction: Int) {
        self.totalReaction = .init(value: totalReaction)
        self.getUser(of: kind)
    }
    
    func next() {
        self.param.accept(.init(pageNum: self.param.value.pageNum + 1, pageSize: self.param.value.pageSize))
    }
    
    func refresh() {
        self.param.accept(.init(pageNum: 1, pageSize: self.param.value.pageSize))
    }
}

extension SimpleListUserReactionPresenter {
    fileprivate func getUser(of kind: ListUserReactionKind) {
        let observable: Observable<([UserReactionInfo], Int)>
        switch kind {
        case .comment(let id):
            observable = self.param.flatMap { (param) -> Observable<([UserReactionInfo], Int)> in
                return CommentPostService.shared.listReactionComment(id: id, pageNum: param.pageNum, pageSize: param.pageSize)
                    .catchError { (error) -> Observable<([UserReactionInfo], Int)> in
                        HandleError.default.showAlert(with: error)
                        return .empty()
                    }
            }
        case .post(let id):
            observable = self.param.flatMap { (param) -> Observable<([UserReactionInfo], Int)> in
                return PostService.shared.getListUserReaction(postId: id, pageNum: param.pageNum, pageSize: param.pageSize)
                    .catchError { (error) -> Observable<([UserReactionInfo], Int)> in
                        HandleError.default.showAlert(with: error)
                        return .empty()
                    }
            }
        }
        observable
            .subscribe (onNext: { (users, total) in
                self.userReactions.accept(users)
                self.totalUser.accept(total)
            })
            .disposed(by: self.disposeBag)
    }
}

extension SimpleListUserReactionPresenter {
    enum ListUserReactionKind {
        case post(Int)
        case comment(Int)
    }
}
