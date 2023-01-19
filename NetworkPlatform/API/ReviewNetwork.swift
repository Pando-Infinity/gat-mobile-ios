import RxSwift

public final class ReviewNetwork {
    private let network: Network<Review>
    
    init(network: Network<Review>) {
        self.network = network
    }
    
    func getMyReviewForBook(editionId: Int) -> Observable<Review> {
        return network.getDataV1("book/selfget_book_evaluation?editionId=\(editionId)")
    }
}
