import Foundation

final class Application {
    static let shared = Application()

    let networkUseCaseProvider: UseCaseProvider

    private init() {
        self.networkUseCaseProvider = UseCaseProviderNetwork()
    }
}
