import Foundation
import RxSwift

final class CActivitiesUseCaseNetwork: CActivitiesUseCase {
    
    private let network: CActivitiesNetwork
    
    init(network: CActivitiesNetwork) {
        self.network = network
    }
    
    func getCActivities(challengeId: Int, pageNum: Int, pageSize: Int) -> Observable<CActivities> {
        return network.getCActivities(challengeId: challengeId, pageNum: pageNum, pageSize: pageSize)
    }
}
