import Foundation
import RxSwift

public protocol CActivitiesUseCase {
    func getCActivities(challengeId: Int, pageNum: Int, pageSize: Int) -> Observable<CActivities>
}
