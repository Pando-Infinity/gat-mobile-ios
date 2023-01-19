import RxSwift

public final class AuthNetwork {
    private let network: Network<Token>
    
    init(network: Network<Token>) {
        self.network = network
    }
    
    func signInWithEmail(signInEmailPost: SignInEmailPost) -> Observable<Token> {
        return network.postData("user/login_by_email", parameters: signInEmailPost.toJSON())
    }
}
