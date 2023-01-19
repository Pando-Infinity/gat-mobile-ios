import SwiftyJSON

public class SignInEmailPost {
    private var email: String
    private var password: String
    private var uuid: String
    
    init(email: String, password: String, uuid: String) {
        self.email = email
        self.password = password
        self.uuid = uuid
    }
    
    func toJSON() -> Dictionary<String, Any> {
        return [
            "email": self.email,
            "password": self.password,
            "uuid": self.uuid
        ]
    }
}
