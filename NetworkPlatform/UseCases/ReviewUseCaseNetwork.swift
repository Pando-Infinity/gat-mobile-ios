import RxSwift

public final class ReviewUseCaseNetwork: ReviewUseCase {
    private let network: ReviewNetwork
    
    init(network: ReviewNetwork) {
        self.network = network
    }
    
    public func getMyReviewForBook(editionId: Int) -> Observable<Review> {
        return network.getMyReviewForBook(editionId: editionId)
    }
}

