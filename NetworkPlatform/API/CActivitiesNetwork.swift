import RxSwift

public final class CActivitiesNetwork {
    private let netwwork: Network<CActivities>
    
    init(network: Network<CActivities>) {
        self.netwwork = network
    }
    
    func getCActivities(challengeId: Int, pageNum: Int = 1, pageSize: Int = 10) -> Observable<CActivities> {
        return netwwork.getItem("challenges/\(challengeId)/activities", params: "?pageNum=\(pageNum)&pageSize=\(pageSize)")
    }
}
