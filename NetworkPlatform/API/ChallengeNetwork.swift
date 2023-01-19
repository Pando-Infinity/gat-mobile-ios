import Foundation
import RxSwift
import Alamofire
import SwiftyJSON

public final class ChallengeNetwork {
    private let network: Network<Challenge>
    
    init(network: Network<Challenge>) {
        self.network = network
    }
    
    func getChallenge(id: Int) -> Observable<Challenge> {
        return network.getItem("challenges", itemId: "\(id)")
    }
}

struct JoinChallengeRequest: APIRequest {
    var path: String {return "challenges/\(self.challenge.id)/_join"}
    
    var method: HTTPMethod {.put}
    
    var challenge:Challenge
    
    var headers: HTTPHeaders? {
        var params: [String: String] = [:]
        params["Authorization"] = "Bearer " + (Session.shared.accessToken ?? "")
        return params
    }
}

struct JoinChallengeResponse: APIResponse {
    func map(data: Data?, statusCode: Int) -> ()? {
        guard let json = self.json(from: data, statusCode: statusCode)  else { return nil }
        print(json)
        return ()
    }
}


struct ChallengeByIDResquest: APIRequest {
    var path: String {return "challenges/\(self.challenge.id)"}
    
    var method: HTTPMethod {.get}
    
    var challenge:Challenge
    
    var headers: HTTPHeaders? {
        var params: [String: String] = [:]
        params["Authorization"] = "Bearer " + (Session.shared.accessToken ?? "")
        return params
    }
}

struct ChallengeByIDRespose: APIResponse {
    func map(data: Data?, statusCode: Int) -> Challenge? {
        guard let json = self.json(from: data, statusCode: statusCode) else {return nil}
        let data = json["data"]
        print("JSONNNN: \(data)")
        let challenge = Challenge(json: data, isInit: true)
        return challenge
    }
}

class NetworkChallengeV2{
    static var shared:NetworkChallengeV2 = NetworkChallengeV2()
    
    fileprivate var dispatcheV2:Dispatcher
    
    fileprivate init() {
        self.dispatcheV2 = SearchDispatcher()
    }
    
    func getChallengeByID(challenge:Challenge) -> Observable<(Challenge)> {
        return self.dispatcheV2.fetch(request: ChallengeByIDResquest(challenge: challenge), handler: ChallengeByIDRespose())
    }
    
    func joinChallenge(challenge:Challenge) -> Observable<()>{
        return self.dispatcheV2.fetch(request: JoinChallengeRequest(challenge: challenge), handler: JoinChallengeResponse())
    }
}
