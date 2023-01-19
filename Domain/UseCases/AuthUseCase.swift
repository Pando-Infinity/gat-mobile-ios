import Foundation
import RxSwift

public protocol AuthUseCase {
    func signInWithEmail(signInEmailPost: SignInEmailPost) -> Observable<Token>
    
    //func signOut() -> Observable<BaseResponse<Any>>
}
