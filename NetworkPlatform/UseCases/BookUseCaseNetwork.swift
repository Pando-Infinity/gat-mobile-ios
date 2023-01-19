import RxSwift

public final class BookUseCaseNetwork: BookUseCase {
    private let network: BookNetwork
    
    init(network: BookNetwork) {
        self.network = network
    }
    
    public func getBook(editionId: Int) -> Observable<Book> {
        return network.getBook(editionId: editionId)
    }
}
