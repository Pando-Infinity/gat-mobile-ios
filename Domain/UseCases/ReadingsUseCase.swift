import Foundation
import RxSwift

public protocol ReadingsUseCase {
    func getMyReadings(userReadingPut: UserReadingPut) -> Observable<Readings>
}
