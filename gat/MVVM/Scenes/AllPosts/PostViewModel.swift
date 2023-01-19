import Foundation
import RxSwift
import RxCocoa
import Alamofire

final class PostViewModel: ViewModelType {
    
    struct Input {
        let loadTrigger: Driver<Void>
    }
    
    struct Output {
        let indicator: Driver<Bool>
        let posts: Driver<Token>
        let error: Driver<Error>
    }
    
    private let useCase: AuthUseCase
    
    init(useCase: AuthUseCase) {
        self.useCase = useCase
    }
    
    func transform(_ input: PostViewModel.Input) -> PostViewModel.Output {
        let indicator = ActivityIndicator()
        let error = ErrorTracker()
        let signIn = SignInEmailPost(email: "cafe.quoclo1@gmail.com", password: "uiop7890", uuid: "A66FCEA6-A5BB-4D8B-9EE1-08AAD8F3D233")
        
        let posts = self.useCase.signInWithEmail(signInEmailPost: signIn)
        .trackActivity(indicator)
        .trackError(error)
        .asDriverOnErrorJustComplete()

        return Output(
            indicator: indicator.asDriver(),
            posts: posts,
            error: error.asDriver()
        )
    }
}
