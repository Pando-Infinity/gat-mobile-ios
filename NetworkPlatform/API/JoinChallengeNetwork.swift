import RxSwift
import Alamofire

public final class JoinChallengeNetwork {
    private let network: Network<BaseModel>
    
    init(network: Network<BaseModel>) {
        self.network = network
    }
    
    func joinChallenge(id: Int, targetNumber: Int) -> Observable<BaseModel> {
        return network.putData("challenges/\(id)/_join", parameters: ["targetNumber": targetNumber], encoding: URLEncoding.default)
    }
}
