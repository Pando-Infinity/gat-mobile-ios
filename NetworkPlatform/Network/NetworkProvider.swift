//
//  NetworkProvider.swift
//  gat
//
//  Created by Hung Nguyen on 12/7/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

final class NetworkProvider {
    private let apiEndpoint: String
    private let apiEndpointV2: String

    public init() {
        apiEndpoint = AppConfig.sharedConfig.config(item: "api_url")!//"https://production.gatbook.org/rest/api/"
        apiEndpointV2 = AppConfig.sharedConfig.config(item: "api_url_v2")! //"https://productionv2.gatbook.org/api/v1/"
    }
    
    public func makeAuthNetwork() -> AuthNetwork {
        let network = Network<Token>(apiEndpoint)
        return AuthNetwork(network: network)
    }
    
    public func makeChallengesNetwork() -> ChallengesNetwork {
        let network = Network<Challenges>(apiEndpointV2)
        return ChallengesNetwork(network: network)
    }
    
    public func makeChallengeNetwork() -> ChallengeNetwork {
        let network = Network<Challenge>(apiEndpointV2)
        return ChallengeNetwork(network: network)
    }
    
    public func makeCActivitiesNetwork() -> CActivitiesNetwork {
        let network = Network<CActivities>(apiEndpointV2)
        return CActivitiesNetwork(network: network)
    }
    
    public func makeJoinChallengeNetwork() -> JoinChallengeNetwork {
        let network = Network<BaseModel>(apiEndpointV2)
        return JoinChallengeNetwork(network: network)
    }
    
    public func makeLeaderBoardsNetwork() -> LeaderBoardsNetwork {
        let network = Network<LeaderBoards>(apiEndpointV2)
        return LeaderBoardsNetwork(network: network)
    }
    
    public func makeReadingNetwork() -> ReadingNetwork {
        let network = Network<UpdateReadingResponse>(apiEndpointV2)
        return ReadingNetwork(network: network)
    }
    
    public func makeBooksNetwork() -> BooksNetwork {
        let network = Network<Books>(apiEndpointV2)
        return BooksNetwork(network: network)
    }
    
    public func makeBookNetwork() -> BookNetwork {
        let network = Network<Book>(apiEndpointV2)
        return BookNetwork(network: network)
    }
    
    public func makeSearchBooksNetwork() -> SearchBooksNetwork {
        let network = Network<SearchBookResponse>(apiEndpointV2)
        return SearchBooksNetwork(network: network)
    }
    
    public func makeReadingsNetwork() -> ReadingsNetwork {
        let network = Network<Readings>(apiEndpointV2)
        return ReadingsNetwork(network: network)
    }
    
    public func makeReviewNetwork() -> ReviewNetwork {
        let network = Network<Review>(apiEndpoint)
        return ReviewNetwork(network: network)
    }
}

