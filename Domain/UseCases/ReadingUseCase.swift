import Foundation
import RxSwift

public protocol ReadingUseCase {
    func addReading(updateReadingPost: UpdateReadingPost) -> Observable<UpdateReadingResponse>
    
    func updateReading(updateReadingPost: UpdateReadingPost) -> Observable<UpdateReadingResponse>
}
