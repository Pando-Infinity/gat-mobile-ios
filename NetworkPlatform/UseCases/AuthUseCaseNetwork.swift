import Foundation
import RxSwift

final class AuthUseCaseNetwork: AuthUseCase {
    
    private let network: AuthNetwork
    
    init(network: AuthNetwork) {
        self.network = network
    }
    
    public func signInWithEmail(signInEmailPost: SignInEmailPost) -> Observable<Token> {
        return network.signInWithEmail(signInEmailPost: signInEmailPost)
    }
    
//    func signInWithFb(signInEmailPost: SignInEmailPost) -> Observable<BaseResponse<Token>> {
//        return network.signInWithEmail(signInEmailPost: signInEmailPost)
//    }
//
//    func signInWithGg(signInEmailPost: SignInEmailPost) -> Observable<BaseResponse<Token>> {
//        return network.signInWithEmail(signInEmailPost: signInEmailPost)
//    }
    
//    func signOut() -> Observable<BaseResponse<Any>> {
//        return Observable<BaseResponse<Any>>
//    }
}
