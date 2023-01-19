import RxSwift

public final class BookNetwork {
    private let network: Network<Book>
    
    init(network: Network<Book>) {
        self.network = network
    }
    
    func getBook(editionId: Int) -> Observable<Book> {
        return network.getData("book_edition/\(editionId)")
    }
}
