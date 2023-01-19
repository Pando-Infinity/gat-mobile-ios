import Foundation
import RxSwift

public protocol ReviewUseCase {
    func getMyReviewForBook(editionId: Int) -> Observable<Review>
}
