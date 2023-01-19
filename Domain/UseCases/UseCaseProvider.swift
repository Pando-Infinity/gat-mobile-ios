//
//  UseCaseProvider.swift
//  gat
//
//  Created by Hung Nguyen on 12/7/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation

public protocol UseCaseProvider {

    func makeAuthUseCase() -> AuthUseCase
    
    func makeChallengesUseCase() -> ChallengesUseCase
    
    func makeChallengeUseCase() -> ChallengeUseCase
    
    func makeCActivitiesUseCase() -> CActivitiesUseCase
    
    func makeJoinChallengeUseCase() -> JoinChallengeUseCase
    
    func makeLeaderBoardsUseCase() -> LeaderBoardsUseCase
    
    func makeReadingUseCase() -> ReadingUseCase
    
    func makeBooksUseCase() -> BooksUseCase
    
    func makeBookUseCase() -> BookUseCase
    
    func makeSearchBooksUseCase() -> SearchBooksUseCase
    
    func makeReadingsUseCase() -> ReadingsUseCase
    
    func makeReviewUseCase() -> ReviewUseCase
}
