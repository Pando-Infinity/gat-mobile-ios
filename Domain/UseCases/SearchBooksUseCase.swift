import Foundation
import RxSwift

public protocol SearchBooksUseCase {
    func searchBooks(searchBookPut: SearchBookPut) -> Observable<SearchBookResponse>
}
