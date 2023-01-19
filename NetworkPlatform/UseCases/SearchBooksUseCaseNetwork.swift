import RxSwift

public final class SearchBooksUseCaseNetwork: SearchBooksUseCase {
    private let network: SearchBooksNetwork
    
    init(network: SearchBooksNetwork) {
        self.network = network
    }
    
    public func searchBooks(searchBookPut: SearchBookPut) -> Observable<SearchBookResponse> {
        return network.searchBooks(searchBookPut: searchBookPut)
    }
}
