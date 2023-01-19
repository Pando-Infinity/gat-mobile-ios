//
//  ChallengeGATUPModel.swift
//  gat
//
//  Created by macOS on 8/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

final class ChallengeGATUPModel: ViewModelType {
    
    struct Input {
        let getBookstop: BehaviorSubject<Bookstop?>
    }
    
    struct Output {
        let indicator: Driver<Bool>
        let challenges: Observable<Challenges>
        let myChallenges: Observable<Challenges>
        let error: Driver<Error>
    }
    
    private let useCase: ChallengesUseCase
    
    init(useCase: ChallengesUseCase) {
        self.useCase = useCase
    }
    
    func transform(_ input: ChallengeGATUPModel.Input) -> ChallengeGATUPModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        let challenges = input.getBookstop
            .compactMap{$0}
            .flatMapLatest { (bookstop) -> Driver<Challenges> in
            return self.useCase.getBookstopChallenges(in: bookstop)
                .trackActivity(indicator)
                .trackError(error)
                .asDriverOnErrorJustComplete()
        }
        
        let myChallenges = input.getBookstop
            .compactMap{$0}
            .flatMapLatest { (bookstop) -> Driver<Challenges> in
            return self.useCase.getMyBookstopChallenges(in: bookstop)
                .asDriverOnErrorJustComplete()
        }
        
        return Output(
            indicator: indicator.asDriver(),
            challenges: challenges,
            myChallenges: myChallenges,
            error: error.asDriver()
        )
    }
}
