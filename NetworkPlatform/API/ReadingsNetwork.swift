import RxSwift

public final class ReadingsNetwork {
    private let network: Network<Readings>
    
    init(network: Network<Readings>) {
        self.network = network
    }
    
    func getMyReadings(userReadingPut: UserReadingPut) -> Observable<Readings> {
        return network.putData("user_reading/_get_user_reading_list", parameters: userReadingPut.toJSON())
    }
}
