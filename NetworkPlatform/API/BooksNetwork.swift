import RxSwift

public final class BooksNetwork {
    private let network: Network<Books>
    
    init(network: Network<Books>) {
        self.network = network
    }
    
    func getTopBorrowingBooks(page: Int, perPage: Int, previousDay: Int) -> Observable<Books> {
        return network.getData("user_reading/suggestion?pageNum=\(page)&pageSize=\(perPage)&previousDays=\(previousDay)", isNeedAuth: true)
    }
}
