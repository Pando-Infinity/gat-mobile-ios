import Foundation
import RxSwift

public protocol BookUseCase {
    func getBook(editionId: Int) -> Observable<Book>
}
