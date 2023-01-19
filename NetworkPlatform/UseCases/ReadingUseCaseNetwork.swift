import Foundation
import RxSwift

final class ReadingUseCaseNetwork: ReadingUseCase {
    private let network: ReadingNetwork
    
    init(network: ReadingNetwork) {
        self.network = network
    }
    
    func addReading(updateReadingPost: UpdateReadingPost) -> Observable<UpdateReadingResponse> {
        return network.addReading(updateReadingPost: updateReadingPost)
    }
    
    func updateReading(updateReadingPost: UpdateReadingPost) -> Observable<UpdateReadingResponse> {
        return network.updateReading(updateReadingPost: updateReadingPost)
    }
}
