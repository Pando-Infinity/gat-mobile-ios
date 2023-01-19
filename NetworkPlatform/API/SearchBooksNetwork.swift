import RxSwift

public final class SearchBooksNetwork {
    private let network: Network<SearchBookResponse>
    
    init(network: Network<SearchBookResponse>) {
        self.network = network
    }
    
    func searchBooks(searchBookPut: SearchBookPut) -> Observable<SearchBookResponse> {
        
        return network.putData("book_edition/search", parameters: searchBookPut.toJSON())
    }
}
