import Foundation
import RxSwift

public protocol BooksUseCase {
    func getTopBorrowingBooks(page: Int, perPage: Int, previousDay: Int) -> Observable<Books>
}
