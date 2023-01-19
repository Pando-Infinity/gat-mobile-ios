import Foundation

public final class UseCaseProviderNetwork: UseCaseProvider {
    private let networkProvider: NetworkProvider

    public init() {
        networkProvider = NetworkProvider()
    }
    
    public func makeAuthUseCase() -> AuthUseCase {
        return AuthUseCaseNetwork(network: networkProvider.makeAuthNetwork())
    }
    
    public func makeChallengesUseCase() -> ChallengesUseCase {
        return ChallengesUseCaseNetwork(network: networkProvider.makeChallengesNetwork())
    }
    
    public func makeChallengeUseCase() -> ChallengeUseCase {
        return ChallengeUseCaseNetwork(network: networkProvider.makeChallengeNetwork())
    }
    
    public func makeCActivitiesUseCase() -> CActivitiesUseCase {
        return CActivitiesUseCaseNetwork(network: networkProvider.makeCActivitiesNetwork())
    }
    
    public func makeJoinChallengeUseCase() -> JoinChallengeUseCase {
        return JoinChallengeUseCaseNetwork(network: networkProvider.makeJoinChallengeNetwork())
    }
    
    public func makeLeaderBoardsUseCase() -> LeaderBoardsUseCase {
        return LeaderBoardsUseCaseNetwork(network: networkProvider.makeLeaderBoardsNetwork())
    }
    
    public func makeReadingUseCase() -> ReadingUseCase {
        return ReadingUseCaseNetwork(network: networkProvider.makeReadingNetwork())
    }
    
    public func makeBooksUseCase() -> BooksUseCase {
        return BooksUseCaseNetwork(network: networkProvider.makeBooksNetwork())
    }
    
    public func makeBookUseCase() -> BookUseCase {
        return BookUseCaseNetwork(network: networkProvider.makeBookNetwork())
    }
    
    public func makeSearchBooksUseCase() -> SearchBooksUseCase {
        return SearchBooksUseCaseNetwork(network: networkProvider.makeSearchBooksNetwork())
    }
    
    public func makeReadingsUseCase() -> ReadingsUseCase {
        return ReadingsUseCaseNetwork(network: networkProvider.makeReadingsNetwork())
    }
    
    public func makeReviewUseCase() -> ReviewUseCase {
        return ReviewUseCaseNetwork(network: networkProvider.makeReviewNetwork())
    }
}
