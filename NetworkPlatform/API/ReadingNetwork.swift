import RxSwift
import Alamofire

public final class ReadingNetwork {
    private let network: Network<UpdateReadingResponse>
    
    init(network: Network<UpdateReadingResponse>) {
        self.network = network
    }
    
    func addReading(updateReadingPost: UpdateReadingPost) -> Observable<UpdateReadingResponse> {
        return network.postData("user_reading", parameters: updateReadingPost.toJSON(),
                                encoding: JSONEncoding.default)
    }
    
    func updateReading(updateReadingPost: UpdateReadingPost) -> Observable<UpdateReadingResponse> {
        return network.patchData("user_reading", parameters: updateReadingPost.toJSON(),
                                encoding: JSONEncoding.default)
    }
}
