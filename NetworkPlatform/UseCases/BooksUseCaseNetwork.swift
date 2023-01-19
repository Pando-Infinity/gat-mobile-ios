import RxSwift

public final class BooksUseCaseNetwork: BooksUseCase {
    private let network: BooksNetwork
    
    init(network: BooksNetwork) {
        self.network = network
    }
    
    public func getTopBorrowingBooks(page: Int, perPage: Int, previousDay: Int) -> Observable<Books> {
        return network.getTopBorrowingBooks(page: page, perPage: perPage, previousDay: previousDay)
    }
}
