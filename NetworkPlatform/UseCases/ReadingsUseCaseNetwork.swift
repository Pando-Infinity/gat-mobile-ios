import RxSwift

public final class ReadingsUseCaseNetwork: ReadingsUseCase {
    private let network: ReadingsNetwork
    
    init(network: ReadingsNetwork) {
        self.network = network
    }
    
    public func getMyReadings(userReadingPut: UserReadingPut) -> Observable<Readings> {
        return network.getMyReadings(userReadingPut: userReadingPut)
    }
}
